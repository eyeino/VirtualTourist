//
//  Photo.swift
//  VirtualTourist
//
//  Created by Ian MacFarlane on 8/17/16.
//  Copyright © 2016 Ian MacFarlane. All rights reserved.
//

import Foundation
import CoreData
import UIKit


class Photo: NSManagedObject {

// Insert code here to add functionality to your managed object subclass
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    convenience init(insertIntoMangedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        let generated = createImageWithColor(UIColor.redColor(), size: CGSize(width: 75, height: 75))
        
        photo = UIImagePNGRepresentation(generated)!
    }
    
    func createImageWithColor(color: UIColor, size: CGSize) -> UIImage {
        let rect = CGRectMake(0, 0, size.width, size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(rect)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
