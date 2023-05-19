//
//  ViewController.swift
//  BarcodeFinder
//
//  Created by jun on 10/30/20.
//  Copyright © 2020 jp.co.agel. All rights reserved.
//

import UIKit

class DataTableViewCell:UITableViewCell {
    @IBOutlet weak var labelIndex: UILabel!
    @IBOutlet weak var textFieldId: UITextField!
    @IBOutlet weak var textFieldDescription: UITextField!
    
}

class ViewController: UIViewController, UITextViewDelegate, ReaderViewControllerDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var labelCount: UILabel!
    
    var codes:[String] = []
    var matchCodes:Set<String> = []
    	
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        overrideUserInterfaceStyle = .light
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
            //let targetTextArray = targetText.text.components(separatedBy: .newlines).filter { !$0.isEmpty }
            dest.targets = Set(self.codes)
            dest.delegate = self
            break
        default:
            break
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return codes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:DataTableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell") as! DataTableViewCell
        cell.labelIndex.text = String(indexPath.row + 1)
        cell.textFieldId.text = codes[indexPath.row]
        
        if self.matchCodes.contains(codes[indexPath.row]) {
            cell.backgroundColor = UIColor.green
            cell.labelIndex.backgroundColor = UIColor.clear
        } else {
            cell.backgroundColor = UIColor.white
            cell.labelIndex.backgroundColor = UIColor.yellow
        }
        return cell
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
    
    func didFinishReader(tag: String, codes: [String]) {
        self.labelCount.text = String(format: "%d/%d", self.matchCodes.count, self.codes.count)
        switch tag {
        case kSegueIdentifier.PREPARE.rawValue:
            self.matchCodes = []
            self.codes = codes
            break
        case kSegueIdentifier.FINDER.rawValue:
            break
        default:
            break
        }
        self.tableView.reloadData()
    }
    
    func didMatchCode(code: String) {
        self.matchCodes.insert(code)
    }
    
    @IBAction func handleActionPrepareScan(_ sender: Any) {
        performSegue(withIdentifier: kSegueIdentifier.PREPARE.rawValue, sender: self)
    }
    
    @IBAction func handleActionScan(_ sender: Any) {
        performSegue(withIdentifier: kSegueIdentifier.FINDER.rawValue, sender: self)
    }
    
}

