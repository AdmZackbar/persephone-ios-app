//
//  ScannerView.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/12/24.
//

import SwiftUI
import VisionKit

@MainActor
struct ScannerView: UIViewControllerRepresentable {
    var barcodeHandler: (String) -> Void
    
    var scannerViewController: DataScannerViewController = DataScannerViewController(
        recognizedDataTypes: [.barcode(symbologies: [.ean13, .upce])],
        qualityLevel: .balanced,
        recognizesMultipleItems: false,
        isHighFrameRateTrackingEnabled: false,
        isHighlightingEnabled: false
    )
   
    func makeUIViewController(context: Context) -> DataScannerViewController {
        scannerViewController.delegate = context.coordinator
        try? scannerViewController.startScanning()
        return scannerViewController
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        // Update any view controller settings here
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var parent: ScannerView
        var roundBoxMappings: [UUID: UIView] = [:]
        
        init(_ parent: ScannerView) {
            self.parent = parent
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            addedItems.forEach { item in
                switch item {
                case .barcode(let code):
                    if (!(code.payloadStringValue ?? "").isEmpty) {
                        parent.barcodeHandler(code.payloadStringValue!)
                        parent.scannerViewController.stopScanning()
                    }
                    break
                default:
                    break
                }
            }
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didRemove removedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            // TODO
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            // TODO
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            // TODO
        }
    }
}

#Preview {
    ScannerView { barcode in
        print(barcode)
    }
}
