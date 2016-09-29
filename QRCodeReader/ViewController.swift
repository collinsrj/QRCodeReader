//
//  ViewController.swift
//  QRCodeReader
//
//  Created by Robert Collins on 30/11/2015.
//  Copyright © 2015 Robert Collins. All rights reserved.
//

import UIKit
import AVFoundation
import Dispatch

class ViewController: UIViewController {

    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private var isReading: Bool = false {
        didSet {
            let buttonText = isReading ? "Stop" : "Start"
            startStopButton.setTitle(buttonText, for: .normal)
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
            let _ = startReading()
            self.statusLabel.text = ""
        }
    }
    
    /**
     Setup the capture session and display the preview allowing users to locate the QR code.
    */
    private func startReading() -> Bool {
        guard let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) else {
            return false
        }
        let input = getCaptureDeviceInput(device: captureDevice)
        
        let captureSession = AVCaptureSession()
        captureSession.addInput(input)
        
        let captureMetadataOutput = AVCaptureMetadataOutput()
        captureSession.addOutput(captureMetadataOutput)

        let dispatchQueue = DispatchQueue(label:"myQueue", attributes: .concurrent)
        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: dispatchQueue)
        captureMetadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
        videoPreviewLayer = AVCaptureVideoPreviewLayer.init(session: captureSession)
        videoPreviewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
        videoPreviewLayer?.frame = previewView.layer.bounds
        previewView.layer.addSublayer(videoPreviewLayer!)
        
        captureSession.startRunning()
        isReading = true
        return true
    }
    
    /**
     Stop reading from the capture session.
     */
    func stopReading() {
        guard let _ = captureSession else {
            return
        }
        captureSession?.stopRunning()
        captureSession = nil
        videoPreviewLayer?.removeFromSuperlayer()
        isReading = false
    }
    
    /**
     Get the input from the device.
     
     - parameter device: A capture device
     - returns: An optional input from the capture device
     */
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
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        guard metadataObjects.count > 0, let metadataObject = metadataObjects[0] as? AVMetadataMachineReadableCodeObject, metadataObject.type == AVMetadataObjectTypeQRCode else {
            return
        }
        DispatchQueue.main.async {
            self.stopReading()
            self.statusLabel.text = metadataObject.stringValue
        }
    }
}
