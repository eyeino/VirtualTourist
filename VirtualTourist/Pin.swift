//
//  Pin.swift
//  VirtualTourist
//
//  Created by Ian MacFarlane on 8/17/16.
//  Copyright © 2016 Ian MacFarlane. All rights reserved.
//

import Foundation
import CoreData


class Pin: NSManagedObject {

// Insert code here to add functionality to your managed object subclass
    convenience init(latitude: Double, longitude: Double, context: NSManagedObjectContext) {
        if let ent = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context) {
            self.init(entity: ent, insertIntoManagedObjectContext: context)
            self.lat = latitude
            self.lon = longitude
        } else {
            fatalError("Unable to find Entity (notebook) name.")
        }
    }
    
}
