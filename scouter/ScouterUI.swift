//
//  ScouterUI.swift
//  scouter
//
//  Created by jun-izumida on 12/9/20.
//  Copyright © 2020 jp.co.agel. All rights reserved.
//

import UIKit

class ScouterButton: UIButton {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.layer.bounds.width / 2
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowRadius = 1
        self.layer.shadowOffset = CGSize(width: 1, height: 1)
        self.layer.shadowOpacity = 0.5
    }
}
