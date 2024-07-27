//
//  ScanFoodView.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/13/24.
//

import AVFoundation
import SwiftData
import SwiftUI

private enum ViewState {
    case Scan
    case Lookup(barcode: String)
    case NoResult(barcode: String)
    case ResultList(items: [FoodItem])
    case ConfirmResult(items: [FoodItem], item: FoodItem)
}

struct ScanFoodView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var modelContext
    
    @State private var viewState: ViewState = .Scan
    @State private var torchOn: Bool = false
    
    var body: some View {
        ZStack {
            switch viewState {
            case .Scan:
                ScannerView(delegate: self)
                    .navigationTitle("Scan Barcode")
                    .toolbarTitleDisplayMode(.inline)
                    .navigationBarBackButtonHidden()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                dismiss()
                            }
                        }
                        ToolbarItem(placement: .primaryAction) {
                            Button {
                                torchOn.toggle()
                                toggleTorch(torchOn)
                            } label: {
                                Label("Light", systemImage: torchOn ? "lightbulb" : "lightbulb.slash")
                            }
                        }
                    }
            case .Lookup(let barcode):
                VStack {
                    Text("Fetching data for \(barcode)...")
                    ProgressView()
                }.navigationTitle("Barcode Lookup")
                    .toolbarTitleDisplayMode(.inline)
            case .NoResult(let barcode):
                Text("No Results for \(barcode)")
                    .navigationTitle("Scan Results")
                    .toolbarTitleDisplayMode(.inline)
                    .navigationBarBackButtonHidden()
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button("Keep Scanning") {
                                viewState = .Scan
                            }
                        }
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                dismiss()
                            }
                        }
                    }
            case .ResultList(let items):
                List(items) { item in
                    Button(item.name) {
                        viewState = .ConfirmResult(items: items, item: item)
                    }
                }.navigationTitle("Select Scanned Item")
                    .toolbarTitleDisplayMode(.inline)
                    .navigationBarBackButtonHidden()
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button("Keep Scanning") {
                                viewState = .Scan
                            }
                        }
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                dismiss()
                            }
                        }
                    }
            case .ConfirmResult(let items, let item):
                ConfirmFoodScanView(items: items, item: item, viewState: $viewState)
            }
        }
    }
    
    func toggleTorch(_ on: Bool) {
        var device: AVCaptureDevice?
        
        if #available(iOS 17, *) {
            device = AVCaptureDevice.userPreferredCamera
        } else {
            // adapted from [https://www.appsloveworld.com/swift/100/46/avcapturesession-freezes-when-torch-is-turned-on] to fix freezing issue when activating torch
            let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTripleCamera, .builtInDualWideCamera, .builtInUltraWideCamera, .builtInWideAngleCamera, .builtInTrueDepthCamera], mediaType: AVMediaType.video, position: .back)
            device = deviceDiscoverySession.devices.first
        }
        guard let device else { return }
        if device.hasTorch && device.isTorchAvailable {
            do {
                try device.lockForConfiguration()
                if on {
                    try device.setTorchModeOn(level: 1.0)
                } else {
                    device.torchMode = .off
                }
                device.unlockForConfiguration()
            } catch {
                print("Torch could not be used")
            }
        } else {
            print("Torch is not available")
        }
    }
}

private struct ConfirmFoodScanView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var modelContext
    @StateObject var sheetCoordinator = SheetCoordinator<FoodSheetEnum>()
    
    let items: [FoodItem]
    let item: FoodItem
    
    @Binding private var viewState: ViewState
    // Name details
    @State private var name: String = ""
    @State private var brand: String = ""
    // Size
    @State private var amountUnit: FoodUnit = .Gram
    @State private var numServings: Double = 0.0
    @State private var servingSize: String = ""
    @State private var totalAmount: Double = 0.0
    private var servingAmount: Double? {
        get {
            if (totalAmount <= 0 || numServings <= 0) {
                return nil
            }
            return totalAmount / numServings
        }
    }
    // Ingredients
    @State private var ingredients: String = ""
    @State private var allergens: String = ""
    
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.zeroSymbol = ""
        formatter.groupingSeparator = ""
        return formatter
    }()
    
    let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    var body: some View {
        Form {
            Section(item.metaData.barcode ?? "unknown barcode") {
                Grid(verticalSpacing: 16) {
                    GridRow {
                        Text("Name:").fontWeight(.light).gridCellAnchor(UnitPoint(x: 0, y: 0.5))
                        TextField("required", text: $name)
                    }
                    GridRow {
                        Text("Brand:").fontWeight(.light).gridCellAnchor(UnitPoint(x: 0, y: 0.5))
                        TextField("optional", text: $brand)
                    }
                    GridRow {
                        Text(amountUnit.isWeight() ? "Net Wt:" : "Net Vol:").fontWeight(.light).gridCellAnchor(UnitPoint(x: 0, y: 0.5))
                        Picker(selection: $amountUnit) {
                            createAmountUnitOption(.Gram)
                            createAmountUnitOption(.Ounce)
                            createAmountUnitOption(.Milliliter)
                            createAmountUnitOption(.FluidOunce)
                        } label: {
                            TextField("required", value: $totalAmount, formatter: formatter)
                                .keyboardType(.decimalPad)
                        }.gridCellAnchor(UnitPoint(x: 0, y: 0.5))
                    }
                    GridRow {
                        Text("Num Servings:").fontWeight(.light).gridCellAnchor(UnitPoint(x: 0, y: 0.5))
                        TextField("required", value: $numServings, formatter: formatter)
                            .keyboardType(.decimalPad)
                    }
                    GridRow {
                        Text("Serving Size:").fontWeight(.light).gridCellAnchor(UnitPoint(x: 0, y: 0.5))
                        if servingAmount != nil {
                            HStack {
                                TextField("required", text: $servingSize)
                                    .textInputAutocapitalization(.words)
                                Spacer()
                                Text("(\(formatter.string(for: servingAmount)!)\(amountUnit.getAbbreviation()))")
                                    .fontWeight(.light)
                                    .italic()
                            }
                        } else {
                            TextField("required", text: $servingSize)
                        }
                    }
                }
            }
            Section("Nutrients") {
                NutrientTableView(nutrients: item.ingredients.nutrients)
                    .contextMenu {
                        Button {
                            sheetCoordinator.presentSheet(.Nutrients(item: item))
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                    }
                Button("Adjust Values...") {
                    sheetCoordinator.presentSheet(.Nutrients(item: item))
                }
            }
            Section("Ingredients") {
                TextEditor(text: $ingredients)
                    .textInputAutocapitalization(.words)
                    .frame(height: 140)
                HStack {
                    Text("Allergens:")
                    TextField("None", text: $allergens)
                        .textInputAutocapitalization(.words)
                }.bold()
            }
            Section("Store Listings") {
                List(item.storeItems) { storeItem in
                    HStack {
                        Text(storeItem.store.name).bold()
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("\(formatter.string(for: storeItem.quantity)!) for \(currencyFormatter.string(for: Double(storeItem.price.cents) / 100.0)!)")
                            if !storeItem.available {
                                Text("(retired)").font(.caption).fontWeight(.thin)
                            }
                        }
                    }.onTapGesture {
                        sheetCoordinator.presentSheet(.StoreItem(foodItem: item, item: storeItem))
                    }.swipeActions(allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            item.storeItems.removeAll(where: { s in s == storeItem })
                        } label: {
                            Label("Delete", systemImage: "trash.fill")
                        }
                    }
                }
                Button("Add Listing...") {
                    sheetCoordinator.presentSheet(.StoreItem(foodItem: item, item: nil))
                }
            }
        }.navigationTitle("Confirm Item Details")
            .toolbarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .sheetCoordinating(coordinator: sheetCoordinator)
            .onAppear {
                name = item.name
                brand = item.metaData.brand ?? ""
                amountUnit = item.size.totalAmount.unit
                numServings = item.size.numServings
                servingSize = item.size.servingSize
                totalAmount = item.size.totalAmount.value
                ingredients = item.ingredients.all
                allergens = item.ingredients.allergens
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(items.count > 1 ? "Back" : "Cancel") {
                        if items.count > 1 {
                            viewState = .ResultList(items: items)
                        } else {
                            viewState = .Scan
                        }
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        item.name = name
                        item.metaData.brand = brand
                        item.size = FoodSize(totalAmount: FoodAmount(value: totalAmount, unit: amountUnit), numServings: numServings, servingSize: servingSize)
                        item.ingredients.all = ingredients
                        item.ingredients.allergens = allergens
                        modelContext.insert(item)
                        dismiss()
                    }
                }
            }
    }
    
    private func createAmountUnitOption(_ unit: FoodUnit) -> some View {
        Text(unit.getAbbreviation()).tag(unit).font(.subheadline).fontWeight(.thin)
    }
    
    init(items: [FoodItem], item: FoodItem, viewState: Binding<ViewState>) {
        self.items = items
        self.item = item
        self._viewState = viewState
    }
}

extension ScanFoodView: ScannerDelegate {
    func barcodeDidScan(_ barcode: String) {
        lookupBarcode(barcode: barcode) { results in
            handleResults(results, barcode: barcode)
        }
    }
    
    func lookupBarcode(barcode: String, completion: @escaping ([FoodItem]) -> Void) {
        viewState = .Lookup(barcode: barcode)
        Task {
            var results: [FoodItem] = []
            results.append(contentsOf: try await FoodDataCentralEndpoint.lookupBarcode(barcode))
            results.append(contentsOf: try await OpenFoodFactsEndpoint.lookupBarcode(barcode))
            completion(results)
        }
    }
    
    func handleResults(_ results: [FoodItem], barcode: String) {
        if results.isEmpty {
            viewState = .NoResult(barcode: barcode)
        } else if results.count == 1 {
            viewState = .ConfirmResult(items: results, item: results.first!)
        } else {
            viewState = .ResultList(items: results)
        }
    }
}

#Preview {
    let container = createTestModelContainer()
    let item = createTestFoodItem(container.mainContext)
    return NavigationStack {
        ConfirmFoodScanView(items: [item], item: item, viewState: .constant(.Scan))
    }.modelContainer(container)
}
