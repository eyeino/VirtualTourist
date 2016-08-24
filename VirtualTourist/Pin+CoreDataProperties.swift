//
//  Pin+CoreDataProperties.swift
//  
//
//  Created by Ian MacFarlane on 8/24/16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Pin {

    @NSManaged var lat: NSNumber?
    @NSManaged var lon: NSNumber?
    @NSManaged var photos: NSSet?
    @NSManaged var id: String?

}
