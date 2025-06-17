import Foundation
import AVFoundation

class BarcodeScannerViewModel {
    // MARK: - Properties
    private(set) var captureSession: AVCaptureSession?
    private(set) var detectedBarcodes: [AVMetadataMachineReadableCodeObject] = []
    private(set) var scannedSerialNumbers: [String] = []
    private(set) var isScanning: Bool = false
    
    var scannerPurpose: ScannerPurpose = .productName
    var existingSerialNumbers: [String] = [] // Dışarıdan gelen mevcut seri numaraları
    var onSerialNumbersScanned: (([String]) -> Void)?
    var onProductNameScanned: ((String) -> Void)?
    
    // MARK: - Methods
    func setupCaptureSession() -> AVCaptureSession? {
        let session = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            return nil
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return nil
        }
        
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        } else {
            return nil
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.metadataObjectTypes = [.qr, .ean8, .ean13, .pdf417, .code128, .code39, .code93, .upce]
        } else {
            return nil
        }
        
        self.captureSession = session
        return session
    }
    
    func updateDetectedBarcodes(_ barcodes: [AVMetadataMachineReadableCodeObject]) {
        detectedBarcodes = barcodes
    }
    
    func addSerialNumber(_ serialNumber: String) -> Bool {
        // Hem mevcut taramalarda hem de dışarıdan gelen seri numaralarında kontrol et
        if !scannedSerialNumbers.contains(serialNumber) && !existingSerialNumbers.contains(serialNumber) {
            scannedSerialNumbers.append(serialNumber)
            return true
        }
        return false
    }
    
    func getScannedSerialNumbers() -> [String] {
        return scannedSerialNumbers
    }
    
    func isSerialNumberExists(_ serialNumber: String) -> Bool {
        return scannedSerialNumbers.contains(serialNumber) || existingSerialNumbers.contains(serialNumber)
    }
    
    func stopScanning() {
        isScanning = false
        detectedBarcodes.removeAll()
    }
    
    func startScanning() {
        isScanning = true
    }
    
    func reset() {
        scannedSerialNumbers.removeAll()
        detectedBarcodes.removeAll()
        isScanning = false
    }
} 