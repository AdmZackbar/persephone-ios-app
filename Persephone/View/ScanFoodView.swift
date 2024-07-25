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
    
    @State private var scannedItems: [FoodItem] = []
    @State private var fetchingData: Bool = false
    @State private var torchOn: Bool = false
    
    var body: some View {
        VStack {
            if fetchingData {
                VStack {
                    Text("Fetching data...")
                    ProgressView()
                }
            } else if !scannedItems.isEmpty {
                List(scannedItems) { item in
                    NavigationLink(item.name) {
                        FoodItemEditor(item: item, mode: .Confirm)
                    }
                }.navigationTitle("Select Scanned Item")
                    .toolbarTitleDisplayMode(.inline)
                    .navigationBarBackButtonHidden()
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button("Keep Scanning") {
                                scannedItems.removeAll()
                            }
                        }
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                dismiss()
                            }
                        }
                    }
            } else {
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
        lookupBarcode(barcode: barcode, completion: handleResults)
    }
    
    func lookupBarcode(barcode: String, completion: @escaping ([FoodItem]) -> Void) {
        fetchingData = true
        Task {
            var results: [FoodItem] = []
            results.append(contentsOf: try await FoodDataCentralEndpoint.lookupBarcode(barcode))
            results.append(contentsOf: try await OpenFoodFactsEndpoint.lookupBarcode(barcode))
            completion(results)
        }
    }
    
    func handleResults(_ results: [FoodItem]) {
        fetchingData = false
        scannedItems = results
    }
}

#Preview {
    NavigationStack {
        ScanFoodView()
    }.modelContainer(createTestModelContainer())
}
