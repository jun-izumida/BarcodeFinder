//
//  ViewController.swift
//  BarcodeFinder
//
//  Created by jun on 10/30/20.
//  Copyright © 2020 jp.co.agel. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextViewDelegate, ReaderViewControllerDelegate {
    @IBOutlet weak var targetText: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let dest = segue.destination as!  ReaderViewController
        
        switch segue.identifier {
        case kSegueIdentifier.PREPARE.rawValue:
            dest.segueIdentifier = kSegueIdentifier.PREPARE.rawValue
            dest.delegate = self
            break
        case kSegueIdentifier.FINDER.rawValue:
            dest.segueIdentifier = kSegueIdentifier.FINDER.rawValue
            let targetTextArray = targetText.text.components(separatedBy: .newlines).filter { !$0.isEmpty }
            dest.targets = Set(targetTextArray)
            dest.delegate = self
            break
        default:
            break
        }
    }
    
    func didFinishReader(tag: String, codes: [String]) {
        print(codes)
        switch tag {
        case kSegueIdentifier.PREPARE.rawValue:
            self.targetText.text = codes.joined(separator: "\n")
            break
        case kSegueIdentifier.FINDER.rawValue:
            break
        default:
            break
        }
    }
    
    
    @IBAction func handleActionPrepareScan(_ sender: Any) {
        performSegue(withIdentifier: kSegueIdentifier.PREPARE.rawValue, sender: self)
    }
    
    @IBAction func handleActionScan(_ sender: Any) {
        performSegue(withIdentifier: kSegueIdentifier.FINDER.rawValue, sender: self)
    }
    
}

