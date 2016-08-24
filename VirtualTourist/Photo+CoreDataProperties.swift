//
//  Photo+CoreDataProperties.swift
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

extension Photo {

    @NSManaged var photo: NSData?
    @NSManaged var url: String?
    @NSManaged var pin: Pin?

}
