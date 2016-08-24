//
//  PhotoCollectionViewController.swift
//  VirtualTourist
//
//  Created by Ian MacFarlane on 8/16/16.
//  Copyright © 2016 Ian MacFarlane. All rights reserved.
//

import UIKit
import MapKit
import CoreData

import Alamofire //Networking framework
import Freddy //Framework that converts JSON to Swift objects

class PhotoCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var refreshCollectionButton: UIBarButtonItem!
    @IBOutlet weak var refreshingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var trashButton: UIBarButtonItem!
    
    // The selected indexes array keeps all of the indexPaths for cells that are "selected". The array is
    // used inside cellForItemAtIndexPath to lower the alpha of selected cells.  You can see how the array
    // works by searchign through the code for 'selectedIndexes'
    var selectedIndexes = [NSIndexPath]()
    
    // Keep the changes. We will keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    var lat: Double = 34.6937
    var lon: Double = 135.5022
    var pin: Pin?
    
    var posts = [FlickrPost]()
    
    var numberOfPages: Int?
    var numberOfPhotos: Int?
    var randomPage: Int?
    
    let reusableIdentifier = "photoCell"
    
    var sharedContext = DataController.sharedInstance().managedObjectContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        numberOfPages = nil
        randomPage = nil
        indicateLoading(true)
        textLabel.hidden = true
        
        // Start the fetched results controller
        var error: NSError?
        do {
            try fetchedResultsController.performFetch()
        } catch let fetchError as NSError {
            error = fetchError
        }
        
        if let error = error {
            print("Error performing initial fetch: \(error)")
        }
        
        if (fetchedResultsController.fetchedObjects?.count == 0) {
            FlickrClient.sharedInstance().getFlickrPages(lat, longitude: lon, hostViewController: self) { success, error in
                
                guard let rand = self.randomPage else {
                    return
                }
                
                FlickrClient.sharedInstance().getFlickrPosts(self.lat, longitude: self.lon, withPageNumber: rand, hostViewController: self, completionHandlerForFlickrPosts: { (success, error) in
                    
                    for post in self.posts {
                        self.addPhotoFromFlickrPost(post)
                    }
                })
            }
            
            DataController.sharedInstance().saveContext()
            
        } else {
            indicateLoading(false)
        }
        
        //Add single annotation to mapView
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        mapView.addAnnotation(annotation)
        
        //Zoom to the annotation
        let regionRadius: CLLocationDistance = 16000
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(annotation.coordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
 
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        updateTrashButton()
    }
    
    @IBAction func refreshCollectionButton(sender: UIBarButtonItem!) {
        
        deleteAllPhotos()
        
        //collectionView.scrollToTop()
        //if numberOfPages was already determined, try to get new photos
        if let pageLimit = numberOfPages {
            
            indicateLoading(true)
            
            self.randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                
            FlickrClient.sharedInstance().getFlickrPosts(self.lat, longitude: self.lon, withPageNumber: self.randomPage!, hostViewController: self, completionHandlerForFlickrPosts: { (success, error) in
                
                for post in self.posts {
                    self.addPhotoFromFlickrPost(post)
                }
                DataController.sharedInstance().saveContext()
            })
        
        //if numberOfPages is nil for whatever reason, try to get a value for it and try to get photos
        } else {
            
            FlickrClient.sharedInstance().getFlickrPages(lat, longitude: lon, hostViewController: self) { success, error in
                
                guard let rand = self.randomPage else {
                    return
                }
                
                FlickrClient.sharedInstance().getFlickrPosts(self.lat, longitude: self.lon, withPageNumber: rand, hostViewController: self, completionHandlerForFlickrPosts: { (success, error) in
                    
                    for post in self.posts {
                        self.addPhotoFromFlickrPost(post)
                    }
                    DataController.sharedInstance().saveContext()
                })
            }
        }
        
        collectionView.scrollToTop()
    }
    
    func indicateLoading(enabled: Bool) {
        
        refreshCollectionButton.enabled = !enabled
        
        if enabled {
            refreshingIndicator.startAnimating()
            refreshCollectionButton.tintColor = UIColor.clearColor()
        } else {
            refreshingIndicator.stopAnimating()
            refreshCollectionButton.tintColor = UIColor.blueColor()
        }
        
    }
    
    // MARK: - NSFetchedResultsController
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        if let pin = self.pin {
            fetchRequest.predicate = NSPredicate(format: "pin == %@", pin)
        }
        
        fetchRequest.sortDescriptors = []
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
}

//MARK: Delegate Functions

extension PhotoCollectionViewController {
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        
        print("number Of Cells: \(sectionInfo.numberOfObjects)")
        return sectionInfo.numberOfObjects
    }
        
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reusableIdentifier, forIndexPath: indexPath) as! PhotoCollectionViewCell
        
        self.configurePhotoCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
        
        // Whenever a cell is tapped we will toggle its presence in the selectedIndexes array
        if let index = selectedIndexes.indexOf(indexPath) {
            selectedIndexes.removeAtIndex(index)
        } else {
            selectedIndexes.append(indexPath)
        }
        
        // Then reconfigure the cell
        self.configurePhotoCell(cell, atIndexPath: indexPath)
        
        // And update the trash button
        updateTrashButton()
    }
 
    
    // MARK: - Fetched Results Controller Delegate
    
    // Whenever changes are made to Core Data the following three methods are invoked. This first method is used to create
    // three fresh arrays to record the index paths that will be changed.
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        
        // We are about to handle some new changes. Start out with empty arrays for each change type
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
        
    }
    
    // The second method may be called multiple times, once for each Color object that is added, deleted, or changed.
    // We store the incex paths into the three arrays.
    
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
            
        case .Insert:
            print("Insert an item")
            // Here we are noting that a new Photo instance has been added to Core Data. We remember its index path
            // so that we can add a cell in "controllerDidChangeContent". Note that the "newIndexPath" parameter has
            // the index path that we want in this case
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            print("Delete an item")
            // Here we are noting that a Photo instance has been deleted from Core Data. We keep remember its index path
            // so that we can remove the corresponding cell in "controllerDidChangeContent". The "indexPath" parameter has
            // value that we want in this case.
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            print("Update an item.")
            // We don't expect Photo instances to change after they are created. But Core Data would
            // notify us of changes if any occured. This can be useful if you want to respond to changes
            // that come about after data is downloaded. For example, when images are downloaded from
            // Flickr in the Virtual Tourist app
            updatedIndexPaths.append(indexPath!)
            break
        case .Move:
            break
        }
    }
    
    // This method is invoked after all of the changed in the current batch have been collected
    // into the three index path arrays (insert, delete, and upate). We now need to loop through the
    // arrays and perform the changes.
    //
    // The most interesting thing about the method is the collection view's "performBatchUpdates" method.
    // Notice that all of the changes are performed inside a closure that is handed to the collection view.
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        print("in controllerDidChangeContent. changes.count: \(insertedIndexPaths.count + deletedIndexPaths.count)")
        
        collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)
    }
        
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
            
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    // MARK: - Actions and Helpers
    
    @IBAction func trashButtonClicked() {
        if !selectedIndexes.isEmpty {
            deleteSelectedPhotos()
        }
        
        updateTrashButton()
    }
    
    func deleteAllPhotos() {
        
        for photo in fetchedResultsController.fetchedObjects as! [Photo] {
            sharedContext.deleteObject(photo)
        }
        
        DataController.sharedInstance().saveContext()
        
        selectedIndexes = [NSIndexPath]()
    }
    
    func deleteSelectedPhotos() {
        var photosToDelete = [Photo]()
        
        for indexPath in selectedIndexes {
            photosToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Photo)
        }
        
        for photo in photosToDelete {
            sharedContext.deleteObject(photo)
        }
        
        DataController.sharedInstance().saveContext()
        
        selectedIndexes = [NSIndexPath]()
    }
    
    func configurePhotoCell(cell: PhotoCollectionViewCell, atIndexPath indexPath: NSIndexPath) {
        
        if let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as? Photo {
            if photo.photo != nil, let data = photo.photo {
                if let image = UIImage(data: data) {
                    cell.photo = image
                }
            } else if photo.photo == nil {
                cell.configure(indexPath, fetchedResultsController: self.fetchedResultsController)
            }
        }
    
        // If the cell is "selected" it's color panel is grayed out
        // we use the Swift `find` function to see if the indexPath is in the array
    
        if let _ = selectedIndexes.indexOf(indexPath) {
            cell.imageView.alpha = 0.3
        } else {
            cell.imageView.alpha = 1.0
        }
    }
    
    func addPhotoFromFlickrPost(post: FlickrPost) {
        
        let photo = Photo(insertIntoMangedObjectContext: sharedContext)
        
        photo.photo = nil
        photo.url = post.squareURL
        photo.pin = pin
        
    }
    
    func updateTrashButton() {
        if selectedIndexes.count > 0 {
            trashButton.tintColor = UIColor.redColor()
            trashButton.enabled = true
        } else {
            trashButton.tintColor = UIColor.clearColor()
            trashButton.enabled = false
        }
    }
}

//MARK: FlowLayout Configuration

extension PhotoCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let spacing: CGFloat = 1
        let itemWidth = (view.bounds.size.width / 2) - (spacing / 2)
        let itemHeight = itemWidth
        return CGSize(width: itemWidth, height: itemHeight)
    }
}