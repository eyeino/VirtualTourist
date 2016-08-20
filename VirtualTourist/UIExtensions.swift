//
//  UIExtensions.swift
//  VirtualTourist
//
//  Created by Ian MacFarlane on 8/19/16.
//  Copyright © 2016 Ian MacFarlane. All rights reserved.
//

import UIKit

extension UIScrollView {
    func scrollToTop() {
        let desiredOffset = CGPoint(x: 0, y: -contentInset.top)
        setContentOffset(desiredOffset, animated: true)
    }
}