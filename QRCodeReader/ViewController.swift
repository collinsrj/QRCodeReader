//
//  ViewController.swift
//  QRCodeReader
//
//  Created by Robert Collins on 30/11/2015.
//  Copyright © 2015 Robert Collins. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private var isReading: Bool = false {
        didSet {
            let buttonText = isReading ? "Stop" : "Start"
            startStopButton.setTitle(buttonText, forState: .Normal)
        }
    }
    
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var startStopButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    @IBAction func start() {
        if isReading {
            stopReading()
        } else {
            startReading()
            self.statusLabel.text = ""
        }
    }
    
    private func startReading() -> Bool {
        let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        let input = getCaptureDeviceInput(captureDevice)
        captureSession = AVCaptureSession()
        captureSession!.addInput(input)
        
        let captureMetadataOutput = AVCaptureMetadataOutput()
        captureSession!.addOutput(captureMetadataOutput)

        let dispatchQueue = dispatch_queue_create("myQueue", nil)
        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: dispatchQueue)
        captureMetadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
        videoPreviewLayer = AVCaptureVideoPreviewLayer.init(session: captureSession!)
        videoPreviewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
        videoPreviewLayer?.frame = previewView.layer.bounds
        previewView.layer.addSublayer(videoPreviewLayer!)
        
        captureSession?.startRunning()
        isReading = true
        return true
    }
    
    private func stopReading() {
        guard let _ = captureSession else {
            return
        }
        captureSession?.stopRunning()
        captureSession = nil
        videoPreviewLayer?.removeFromSuperlayer()
        isReading = false
    }
    
    private func getCaptureDeviceInput(device: AVCaptureDevice) -> AVCaptureDeviceInput? {
        do {
            let input = try AVCaptureDeviceInput.init(device: device)
            return input
        } catch {
            return nil
        }
    }
}

extension ViewController: AVCaptureMetadataOutputObjectsDelegate {
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        guard metadataObjects.count > 0 else {
            return
        }
        guard let metadataObject = metadataObjects[0] as? AVMetadataMachineReadableCodeObject where metadataObject.type == AVMetadataObjectTypeQRCode else {
            return
        }
        dispatch_async(dispatch_get_main_queue()) {
            self.stopReading()
            self.statusLabel.text = metadataObject.stringValue
        }
        debugPrint(metadataObject)
    }
}