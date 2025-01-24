//
//  CameraManager.swift
//  VisionExample
//
//  Created by Luo Lab on 1/13/25.
//  Copyright © 2025 Google Inc. All rights reserved.
//


import AVFoundation
import MLKitVision
import UIKit

protocol CameraManagerDelegate: AnyObject {
    /// Called for each frame, providing a VisionImage if you'd like to run text recognition, etc.
    func cameraManagerDidOutput(_ manager: CameraManager, visionImage: VisionImage)
}

/// Manages camera capture session & sampleBuffer feed.
class CameraManager: NSObject {
    
    private(set) var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    weak var delegate: CameraManagerDelegate?
    
    /// Creates and starts the capture session
    func startCamera(in parentView: UIView) {
        let session = AVCaptureSession()
        session.sessionPreset = .high
        
        guard let device = AVCaptureDevice.default(for: .video) else {
            fatalError("No .video device available!")
        }
        
        guard let input = try? AVCaptureDeviceInput(device: device) else {
            fatalError("Can't create camera input!")
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String : kCVPixelFormatType_32BGRA
        ]
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "CameraFeedQueue"))
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        // Create preview layer
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = parentView.bounds
        parentView.layer.addSublayer(layer)
        
        // Keep references
        self.captureSession = session
        self.previewLayer = layer
        
        // Start
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }
    
    /// Stop the capture session
    func stopCamera() {
        captureSession?.stopRunning()
    }
    
    /// Returns the underlying preview layer (if you need bounding box conversions)
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        return previewLayer
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection)
    {
        guard let delegate = delegate else { return }
        // Create VisionImage
        let visionImage = VisionImage(buffer: sampleBuffer)
        // Typically .right if phone is in portrait
        visionImage.orientation = .right
        
        delegate.cameraManagerDidOutput(self, visionImage: visionImage)
    }
}
