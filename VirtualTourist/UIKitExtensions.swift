//
//  UIExtensions.swift
//  VirtualTourist
//
//  Created by Ian MacFarlane on 8/19/16.
//  Copyright © 2016 Ian MacFarlane. All rights reserved.
//

import UIKit

extension UIScrollView {
    
    //Scrolls to the top of a UIScrollView when called
    func scrollToTop() {
        let desiredOffset = CGPoint(x: 0, y: -contentInset.top)
        setContentOffset(desiredOffset, animated: true)
    }
}

extension UIImageView {
    //Applies tint to UIImageView
    func tintImageColor(color: UIColor) {
        self.image = self.image!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        self.tintColor = color
    }
    
}