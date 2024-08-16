//
//  ScanFoodView.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/13/24.
//

import AVFoundation
import SwiftData
import SwiftUI

struct ScanFoodView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var modelContext
    @StateObject var sheetCoordinator = SheetCoordinator<FoodSheetEnum>()
    
    private enum ViewState {
        case Scan
        case Lookup(barcode: String)
        case NoResult(barcode: String)
        case ResultList(items: [FoodItem])
    }
    
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
                        sheetCoordinator.presentSheet(.Confirm(item: item))
                    }
                }.navigationTitle("Select Scanned Item")
                    .toolbarTitleDisplayMode(.inline)
                    .navigationBarBackButtonHidden()
                    .sheetCoordinating(coordinator: sheetCoordinator)
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
        } else {
            viewState = .ResultList(items: results)
        }
    }
}

#Preview {
    ScannerView()
}
