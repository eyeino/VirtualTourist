//
//  PhotoCollectionViewCell.swift
//  VirtualTourist
//
//  Created by Ian MacFarlane on 8/17/16.
//  Copyright © 2016 Ian MacFarlane. All rights reserved.
//

import UIKit
import Alamofire
import CoreData

//Custom cell for collectionView
class PhotoCollectionViewCell: UICollectionViewCell, NSFetchedResultsControllerDelegate {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var loadingIndicator: UIActivityIndicatorView!
    
    var photo: UIImage? {
        set {
            self.imageView.image = newValue
        }
        
        get {
            return imageView.image
        }
    }
    
    var pin: Pin?
    var request: Request?
    var flickrPost: FlickrPost!
    var sharedContext = DataController.sharedInstance().managedObjectContext
    
    func initialize(flickrPost: FlickrPost) {
        self.flickrPost = flickrPost
        self.imageView.image = nil
    }
    
    func configure(indexPath: NSIndexPath, fetchedResultsController: NSFetchedResultsController) {
        print("in cell configure")
        reset()
        loadImage(indexPath, fetchedResultsController: fetchedResultsController)
    }
    
    func reset() {
        imageView.image = nil
        request?.cancel()
    }
    
    func loadImage(indexPath: NSIndexPath, fetchedResultsController: NSFetchedResultsController) {
        print("in cell loadImage")
        
        loadingIndicator.startAnimating()
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        guard let urlString = photo.url else {
            //if url was somehow not initialized, set the cell to empty
            photo.photo = nil
            DataController.sharedInstance().saveContext()
            
            return
        }
        
        guard let url = NSURL(string: urlString) else {
            //if url was somehow not initialized, set the cell to empty
            photo.photo = nil
            DataController.sharedInstance().saveContext()
            
            return
        }
        
        //let mutableURLRequest = NSMutableURLRequest(URL: url)
        //mutableURLRequest.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
        print("requesting thumbnail for cell")
        
        request = Alamofire.request(.GET, url)
            .validate()
            .responseData (completionHandler: { response in
                switch(response.result) {
                case .Success:
                    if let data = response.data {
                        dispatch_async(dispatch_get_main_queue(), {
                            //Deserialize the response data into an image and apply it to the cell
                            photo.photo = data
                            DataController.sharedInstance().saveContext()
                        })
                    }
                case .Failure:
                    dispatch_async(dispatch_get_main_queue(), {
                        photo.photo = nil
                        DataController.sharedInstance().saveContext()
                        
                    })
                }
            })
    }
    
    func populateCell(image: UIImage) {
        print("in cell populateCell")
        
        loadingIndicator.stopAnimating()
        imageView.image = image
        
        //insert photo into sharedcontext and save upon loading
        //_ = Photo(image: image, context: sharedContext)
        //DataController.sharedInstance().saveContext()
    }
    
    func emptyCell() {
        loadingIndicator.stopAnimating()
        imageView.image = nil
    }
    
}