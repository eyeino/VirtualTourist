//
//  PhotoCollectionViewCell.swift
//  VirtualTourist
//
//  Created by Ian MacFarlane on 8/17/16.
//  Copyright © 2016 Ian MacFarlane. All rights reserved.
//

import UIKit
import Alamofire

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
        
        guard let url = flickrPost.squareURL else {
            self.emptyCell()
            return
        }
        
        request = Alamofire.request(.GET, url) .responseData (completionHandler: { response in
            if let data = response.data {
                dispatch_async(dispatch_get_main_queue(), {
                    if let image = UIImage(data: data) {
                        self.populateCell(image)
                    }
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
    }
    
}