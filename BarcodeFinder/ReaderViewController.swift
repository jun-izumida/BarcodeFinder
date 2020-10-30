//
//  ReaderViewController.swift
//  BarcodeFinder
//
//  Created by jun on 10/30/20.
//  Copyright © 2020 jp.co.agel. All rights reserved.
//

import UIKit
import AVFoundation
import AudioToolbox

class ReaderViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var targets:Set<String> = []
    var segueIdentifier:String = ""
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var markers: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if markers.superview != nil {
            markers.removeFromSuperview()
        }
        markers = UIView()
        markers.backgroundColor = .clear
        
        for obj in metadataObjects {
            guard let readableObject = obj as? AVMetadataMachineReadableCodeObject else { continue }
            guard let stringValue = readableObject.stringValue else { continue }
            
            if markers.superview != nil {
                markers.removeFromSuperview()
            }
            markers = UIView()
            markers.backgroundColor = .clear
            
            switch segueIdentifier {
            case kSegueIdentifier.PREPARE.rawValue:
                break
            case kSegueIdentifier.FINDER.rawValue:
                let symbol = self.previewLayer.transformedMetadataObject(for: readableObject) as! AVMetadataMachineReadableCodeObject
                
                if targets.contains(stringValue) {
                    markers.addSubview(self.marker(frame: symbol.bounds, isFill:true))
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                    AudioServicesPlaySystemSound(1108)
                } else {
                    markers.addSubview(self.marker(frame: symbol.bounds, isFill:false))
                }
                break
            default:
                break
            }

            self.previewLayer.addSublayer(markers.layer)
        }
    }

    func marker(frame: CGRect, isFill:Bool) -> UIView! {
        let v = UIView()
        if isFill {
            v.layer.backgroundColor = UIColor.green.cgColor
            v.alpha = 0.5
        }
        v.layer.borderWidth = 2.0
        v.layer.borderColor = UIColor.green.cgColor
        v.frame = frame
        return v
    }
    
    func startReading() {
        self.captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }
        
        let metaDataOutput = AVCaptureMetadataOutput()
        
        if (captureSession.canAddOutput(metaDataOutput)) {
            captureSession.addOutput(metaDataOutput)
            metaDataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metaDataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }
        
        setupPreviewLayer()
        captureSession.startRunning()
    }
    
    func setupPreviewLayer() {
        let ifOrientation = { () -> UIInterfaceOrientation in
            if #available(iOS 13, *) {
                return self.view.window?.windowScene?.interfaceOrientation ?? .unknown
            } else {
                return UIApplication.shared.statusBarOrientation
            }
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.videoOrientation = transformOrientation(orientation: ifOrientation())
        view.layer.addSublayer(previewLayer)
        /*
        if READMODE == "M" {
            let pip = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height))
            pip.backgroundColor = .clear
           
            table = UITableView(frame: CGRect(x: 0, y: 0, width: pip.bounds.width, height: pip.bounds.height / 2), style: .plain)
            table.register(ReaderDataCell.self, forCellReuseIdentifier: "cell")
            table.backgroundView?.backgroundColor = .clear
            table.backgroundColor = .clear
            table.alpha = 0.5
           
            table.dataSource = self
            table.delegate = self
            table.rowHeight = 34
            pip.addSubview(table)
            
            pipLabel = UILabel(frame: CGRect(x: 20, y: pip.bounds.height - 160, width: pip.frame.width / 2, height: 60))
            pipLabel.font = UIFont.systemFont(ofSize: 46, weight: .semibold)
            pipLabel.textColor = UIColor.yellow
            pipLabel.shadowOffset = CGSize(width: 2, height: 2)
            pipLabel.shadowColor = UIColor.black
            pip.addSubview(pipLabel)
            
            self.view.addSubview(pip)
        }
 */
    }
    
    func transformOrientation(orientation: UIInterfaceOrientation) -> AVCaptureVideoOrientation {
        switch orientation {
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        case .portraitUpsideDown:
            return .portraitUpsideDown
        default:
            return .portrait
        }
    }
    
    func convertUIOrientation2VideoOrientation(f: () -> UIInterfaceOrientation) -> AVCaptureVideoOrientation? {
        let v = f()
        switch v {
        case UIInterfaceOrientation.unknown:
            return nil
        default:
            return ([
                UIInterfaceOrientation.portrait: AVCaptureVideoOrientation.portrait,
                UIInterfaceOrientation.portraitUpsideDown: AVCaptureVideoOrientation.portraitUpsideDown,
                UIInterfaceOrientation.landscapeLeft: AVCaptureVideoOrientation.landscapeLeft,
                UIInterfaceOrientation.landscapeRight: AVCaptureVideoOrientation.landscapeRight
            ])[v]
        }
    }
    
    func videoPreviewLayerOrientation() {
        let ifOrientation = { () -> UIInterfaceOrientation in
            if #available(iOS 13, *) {
                return self.view.window?.windowScene?.interfaceOrientation ?? .unknown
            } else {
                return UIApplication.shared.statusBarOrientation
            }
        }
        if let orientation = self.convertUIOrientation2VideoOrientation(f: { return ifOrientation() }) {
            self.previewLayer.connection?.videoOrientation = orientation
        }
    }
    
    func failed()  {
        let ac = UIAlertController(title: "Scanning not supportd", message: "Camera", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Close", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
}