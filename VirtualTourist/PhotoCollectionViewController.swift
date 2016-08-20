//
//  PhotoCollectionViewController.swift
//  VirtualTourist
//
//  Created by Ian MacFarlane on 8/16/16.
//  Copyright © 2016 Ian MacFarlane. All rights reserved.
//

import Foundation
import UIKit
import MapKit

import Alamofire
import Freddy

class PhotoCollectionViewController: UIViewController, UICollectionViewDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var refreshCollectionButton: UIBarButtonItem!
    @IBOutlet weak var refreshingIndicator: UIActivityIndicatorView!
    
    var lat: Double = 34.6937
    var lon: Double = 135.5022
    
    var posts = [FlickrPost]()
    
    var numberOfPages: Int?
    var numberOfPhotos: Int?
    
    let reusableIdentifier = "photoCell"
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        numberOfPages = nil
        
        //Add single annotation to mapView
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        mapView.addAnnotation(annotation)
        
        //Zoom to the annotation
        let regionRadius: CLLocationDistance = 16000
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(annotation.coordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
        
        indicateLoading(true)
        textLabel.hidden = true
        
        //Get photos from Flickr
        FlickrClient.sharedInstance().getFlickrPages(lat, longitude: lon, hostViewController: self)
    }
    
    @IBAction func refreshCollectionButton(sender: UIBarButtonItem!) {
        
        collectionView.scrollToTop()
        //if numberOfPages was already determined, try to get new photos
        if let pageLimit = numberOfPages {
            
            indicateLoading(true)
            
            let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
            
            FlickrClient.sharedInstance().getFlickrPosts(lat, longitude: lon, withPageNumber: randomPage, hostViewController: self)
        
        //if numberOfPages is nil for whatever reason, try to get a value for it and try to get photos
        } else {
            
            FlickrClient.sharedInstance().getFlickrPages(lat, longitude: lon, hostViewController: self)
        }
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
}

//MARK: Delegate Functions

extension PhotoCollectionViewController {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
        
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reusableIdentifier, forIndexPath: indexPath) as! PhotoCollectionViewCell
            cell.configure(posts[indexPath.row])
        return cell
    }
        
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
            
        collectionView?.collectionViewLayout.invalidateLayout()
    }
        
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
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