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
    
    var lat: Double = 34.6937
    var lon: Double = 135.5022
    
    var posts = [FlickrPost]()
    
    var numberOfPages: Int?
    var numberOfPhotos: Int?
    
    let reusableIdentifier = "photoCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //registerCollectionViewCells()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        mapView.addAnnotation(annotation)
        
        //zoom to the new annotation
        let regionRadius: CLLocationDistance = 1000
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(annotation.coordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
        
        refreshCollectionButton.enabled = false
        textLabel.hidden = true
        
        getFlickrPages(lat, longitude: lon)
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    private func getFlickrPages(latitude: Double, longitude: Double) {
        
        let methodParameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.BoundingBox: bboxString(),
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.SquareURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback
        ]
        
        Alamofire.request(.GET, flickrURL(), parameters: methodParameters) .responseJSON { response in
            if let data = response.data {
                do {
                    let json = try JSON(data: data)
                    let pages = try json.int(Constants.FlickrResponseKeys.Photos, Constants.FlickrResponseKeys.Pages)
                    
                    let pageLimit = min(pages, Constants.Flickr.maxPages)
                    let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                    
                    self.numberOfPages = pageLimit
                    
                    self.getFlickrPosts(latitude, longitude: longitude, withPageNumber: randomPage)
                    
                } catch {
                    print("Error with parsing JSON. (latlon request)")
                }
            }
        }
    }
    
    private func getFlickrPosts(latitude: Double, longitude: Double, withPageNumber: Int) {
        
        let methodParameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.BoundingBox: bboxString(),
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.SquareURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback,
            Constants.FlickrParameterKeys.Page: String(withPageNumber)
        ]
        
        Alamofire.request(.GET, flickrURL(), parameters: methodParameters) .responseJSON { response in
            
            if let data = response.data {
                do {
                    let json = try JSON(data: data)
                    let posts = try json.array(Constants.FlickrResponseKeys.Photos, Constants.FlickrResponseKeys.Photo).map(FlickrPost.init)
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        
                        self.posts = posts
                        
                        if posts.isEmpty {
                            self.textLabel.hidden = false
                        } else {
                            self.textLabel.hidden = true
                        }
                        
                        self.refreshCollectionButton.enabled = true
                        self.collectionView.reloadData()
                    })
                    
                } catch {
                    print("Error with parsing JSON. (latlonpage request)")
                }
            }
        }
        
    }
    
    private func flickrURL() -> NSURL {
        
        let components = NSURLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [NSURLQueryItem]()
        
        return components.URL!
    }
    
    private func bboxString() -> String {
        // ensure bbox is bounded by minimum and maximums
        let latitude = lat
        let longitude = lon
        let minimumLon = max(longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
        let minimumLat = max(latitude - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
        let maximumLon = min(longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
        let maximumLat = min(latitude + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
        
    }
    
    @IBAction func refreshCollectionButton(sender: UIBarButtonItem!) {
        
        if let pageLimit = numberOfPages {
            
            refreshCollectionButton.enabled = false
            
            let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
            
            getFlickrPosts(lat, longitude: lon, withPageNumber: randomPage)
        } else {
            getFlickrPages(lat, longitude: lon)
        }
    }
    
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
    
    func registerCollectionViewCells() {
        collectionView?.registerNib(UINib(nibName: "PhotoCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: reusableIdentifier)
    }
    
}

extension PhotoCollectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let spacing: CGFloat = 1
        let itemWidth = (view.bounds.size.width / 2) - (spacing / 2)
        let itemHeight = itemWidth
        return CGSize(width: itemWidth, height: itemHeight)
    }
}