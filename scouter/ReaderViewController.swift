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

protocol ReaderViewControllerDelegate {
    func didFinishReader(tag:String, codes:[String])
    func didMatchCode(code: String)
}

class ReaderViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, AVCaptureMetadataOutputObjectsDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var delegate:ReaderViewControllerDelegate?
    var targets:Set<String> = []
    var match:Set<String> = []
    var savedImages:[UIImage] = []
    var segueIdentifier:String = ""
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var markers: UIView! = UIView()
    var isPlaying:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.startReading()
    }
    
    override func viewWillLayoutSubviews() {
        self.setupOverlayControl()
        self.videoPreviewLayerOrientation()
        //self.view.bringSubviewToFront(collectionView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if (self.captureSession.isRunning == false) {
            DispatchQueue.global(qos: .background).async {
                self.captureSession.startRunning()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if (self.captureSession.isRunning == true) {
            self.captureSession.stopRunning()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animateAlongsideTransition(in: nil) { (animation) in
        } completion: { (UIViewControllerTransitionCoordinatorContext) in
            self.videoPreviewLayerOrientation()
        }

    }
        
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("ABC")
        view.endEditing(true)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return savedImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        
        let img = cell.viewWithTag(1) as! UIImageView
        img
            .image = savedImages[indexPath.row]
        return cell
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
                        
            switch segueIdentifier {
            case kSegueIdentifier.PREPARE.rawValue:
                let symbol = self.previewLayer.transformedMetadataObject(for: readableObject) as! AVMetadataMachineReadableCodeObject
                if targets.contains(stringValue) {
                    markers.addSubview(self.marker(value: stringValue, frame: symbol.bounds, isFill:true))
                 } else {
                    markers.addSubview(self.marker(value: stringValue, frame: symbol.bounds, isFill:false))
                    targets.insert(stringValue)
                 }
                break
            case kSegueIdentifier.FINDER.rawValue:
                let symbol = self.previewLayer.transformedMetadataObject(for: readableObject) as! AVMetadataMachineReadableCodeObject
                
                if targets.contains(stringValue) {
                    markers.addSubview(self.marker(value: stringValue, frame: symbol.bounds, color:UIColor.red, isFill:true))
                    if !self.isPlaying {
                        self.isPlaying = true
                        AudioServicesPlaySystemSoundWithCompletion(kSystemSoundID_Vibrate) {
                            AudioServicesPlaySystemSoundWithCompletion(1003) {
                                self.isPlaying = false
                            }
                        }
                    }
                    //AudioServicesPlaySystemSound(1108)
                    self.handleMatch(code: stringValue)

                    if !match.contains(stringValue) {
                        match.insert(stringValue)
                        /*
                        UIGraphicsBeginImageContextWithOptions(UIScreen.main.bounds.size, false, 0.0)
                        self.view.drawHierarchy(in: self.view.bounds, afterScreenUpdates: true)
                        let image:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
                        UIGraphicsEndImageContext()
                        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                        savedImages.append(image)
                        self.collectionView.reloadData()
                        */
                    }
                } else {
                    markers.addSubview(self.marker(value: stringValue, frame: symbol.bounds, color:UIColor.gray, isFill:true))
                }
                break
            default:
                break
            }

            self.previewLayer.addSublayer(markers.layer)
        }
    }

    func marker(value: String, frame: CGRect, color:UIColor = UIColor.green, isFill:Bool = true) -> UIView! {
        let offset = frame.origin.x - ((300 - frame.width) / 2)
        let marker: UIView = UIView(frame:
                                        CGRect(
                                            x: offset,
                                            y: frame.origin.y,
                                            width: 300,
                                            height: frame.height + 20))
        marker.backgroundColor = UIColor.clear
        
 //       let v = UIView()
        let v = UIView(frame: CGRect(origin: CGPoint(x: ((300 - frame.width) / 2), y: 0), size: CGSize(width: frame.width, height: frame.height)))
        if isFill {
            v.layer.backgroundColor = color.cgColor
            v.alpha = 0.5
        }
        v.layer.borderWidth = 2.0
        v.layer.borderColor = color.cgColor
//        v.frame = frame

        let l = UILabel(frame: CGRect(origin: CGPoint(x: 0, y: frame.height), size: CGSize(width: 300, height: 20)))
        l.text = value
        l.textAlignment = NSTextAlignment.center
        l.tintColor = color
        
        marker.addSubview(v)
        marker.addSubview(l)
        
        return marker
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
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
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
    }
    
    func setupOverlayControl() {
        let cancelButton:UIButton = UIButton(frame: CGRect(x: view.bounds.width - 65 , y: 20, width: 60, height: 60))
        cancelButton.setImage(UIImage(named: "Close"), for: .normal)
        cancelButton.addTarget(self, action: #selector(self.handleClose(sender:)), for: .touchUpInside)
        self.view.addSubview(cancelButton)
        
        if self.segueIdentifier == kSegueIdentifier.PREPARE.rawValue {
            let doneButton:UIButton = UIButton(frame: CGRect(x: view.bounds.width - 65 , y: view.bounds.height - 100, width: 60, height: 60))
            doneButton.setImage(UIImage(named: "Done"), for: .normal)
            doneButton.addTarget(self, action: #selector(self.handleDone(sender:)), for: .touchUpInside)
            self.view.addSubview(doneButton)
        }
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
//            self.previewLayer.connection?.videoOrientation = orientation
        }
    }
    
    func failed()  {
        let ac = UIAlertController(title: "Scanning not supportd", message: "Camera", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Close", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
    
    func handleMatch(code:String) {
        self.delegate?.didMatchCode(code: code)
    }
    
    @objc func handleDone(sender:Any?) {
        self.delegate?.didFinishReader(tag: self.segueIdentifier, codes: Array(self.targets))
        self.handleClose(sender: sender)
    }
    
    @objc func handleClose(sender:Any?) {
        self.delegate?.didFinishReader(tag: self.segueIdentifier, codes:Array(self.targets))
        if (self.captureSession.isRunning == true) {
            self.captureSession.stopRunning()
        }
        if self.presentingViewController is UINavigationController {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
}
