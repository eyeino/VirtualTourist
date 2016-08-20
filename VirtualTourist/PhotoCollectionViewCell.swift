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
    
    var request: Request?
    var flickrPost: FlickrPost!
    
    func configure(flickrPost: FlickrPost) {
        self.flickrPost = flickrPost
        reset()
        loadImage()
    }
    
    func reset() {
        imageView.image = nil
        request?.cancel()
    }
    
    func loadImage() {
        loadingIndicator.startAnimating()
        
        guard let urlString = flickrPost.squareURL else {
            //if url was somehow not initialized, set the cell to empty
            self.emptyCell()
            return
        }
        
        guard let url = NSURL(string: urlString) else {
            //if url was somehow not initialized, set the cell to empty
            self.emptyCell()
            return
        }
        
        //let mutableURLRequest = NSMutableURLRequest(URL: url)
        //mutableURLRequest.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
        
        request = Alamofire.request(.GET, url)
            .validate()
            .responseData (completionHandler: { response in
                switch(response.result) {
                case .Success:
                    if let data = response.data {
                        dispatch_async(dispatch_get_main_queue(), {
                            //Deserialize the response data into an image and apply it to the cell
                            if let image = UIImage(data: data) {
                                self.populateCell(image)
                            }
                        })
                    }
                case .Failure:
                    dispatch_async(dispatch_get_main_queue(), { 
                        self.emptyCell()
                    })
                }
            })
    }
    
    func populateCell(image: UIImage) {
        loadingIndicator.stopAnimating()
        imageView.image = image
    }
    
    func emptyCell() {
        loadingIndicator.stopAnimating()
        imageView.image = nil
    }
    
}