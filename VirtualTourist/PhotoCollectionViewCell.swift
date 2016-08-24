//
//  PhotoCollectionViewCell.swift
//  VirtualTourist
//
//  Created by Ian MacFarlane on 8/17/16.
//  Copyright © 2016 Ian MacFarlane. All rights reserved.
//

import UIKit
import Alamofire

//Custom cell for collectionView
class PhotoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var loadingIndicator: UIActivityIndicatorView!
    
    var photo: UIImage {
        set {
            self.imageView.image = newValue
        }
        
        get {
            return imageView.image ?? createImageWithColor(UIColor.clearColor(), size: CGSize(width: 150, height: 150))
        }
    }
    
    var pin: Pin?
    var request: Request?
    var flickrPost: FlickrPost!
    var sharedContext = DataController.sharedInstance().managedObjectContext
    
    func configure(flickrPost: FlickrPost) {
        print("in cell configure")
        self.flickrPost = flickrPost
        reset()
        loadImage()
    }
    
    func reset() {
        imageView.image = nil
        request?.cancel()
    }
    
    func loadImage() {
        print("in cell loadImage")
        
        loadingIndicator.startAnimating()
        
        let photo = Photo(insertIntoMangedObjectContext: self.sharedContext)
        
        guard let urlString = flickrPost.squareURL else {
            //if url was somehow not initialized, set the cell to empty
            let placeholder = self.createImageWithColor(UIColor.grayColor(), size: CGSize(width: 150, height: 150))
            photo.photo = UIImagePNGRepresentation(placeholder)
            DataController.sharedInstance().saveContext()
            
            return
        }
        
        guard let url = NSURL(string: urlString) else {
            //if url was somehow not initialized, set the cell to empty
            let placeholder = self.createImageWithColor(UIColor.grayColor(), size: CGSize(width: 150, height: 150))
            photo.photo = UIImagePNGRepresentation(placeholder)
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
                        let placeholder = self.createImageWithColor(UIColor.grayColor(), size: CGSize(width: 150, height: 150))
                        photo.photo = UIImagePNGRepresentation(placeholder)
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