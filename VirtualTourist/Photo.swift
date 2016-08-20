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
    convenience init(image: UIImage, context: NSManagedObjectContext) {
        if let ent = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context) {
            self.init(entity: ent, insertIntoManagedObjectContext: context)
            self.photo = UIImagePNGRepresentation(image)
        } else {
            fatalError("Unable to find Entity (notebook) name.")
        }
    }
}
