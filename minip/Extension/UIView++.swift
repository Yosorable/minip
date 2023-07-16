//
//  UIView++.swift
//  minip
//
//  Created by ByteDance on 2023/7/15.
//

import UIKit


extension UIView {
    
    func addTapGesture(action : @escaping ()->Void ){
        let tap = TapGestureRecognizer(target: self , action: #selector(self.handleTap(_:)))
        tap.action = action
        tap.numberOfTapsRequired = 1
        
        self.addGestureRecognizer(tap)
        self.isUserInteractionEnabled = true
        
    }
    @objc func handleTap(_ sender: TapGestureRecognizer) {
        sender.action!()
    }
}

class TapGestureRecognizer: UITapGestureRecognizer {
    var action : (()->Void)? = nil
}
