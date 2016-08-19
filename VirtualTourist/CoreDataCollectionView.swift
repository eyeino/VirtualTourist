//
//  CoreDataCollectionView.swift
//  VirtualTourist
//
//  Created by Ian MacFarlane on 8/18/16.
//  Copyright © 2016 Ian MacFarlane. All rights reserved.
//

import UIKit
import CoreData

class CoreDataCollectionView: UICollectionView {
    
    var fetchedResultsController: NSFetchedResultsController? {
        didSet {
            
        }
    }
}