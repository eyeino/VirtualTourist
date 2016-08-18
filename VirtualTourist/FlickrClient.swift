//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Ian MacFarlane on 8/18/16.
//  Copyright © 2016 Ian MacFarlane. All rights reserved.
//

import Foundation
import Alamofire
import Freddy

class FlickrClient: NSObject {
    
    override init() {
        super.init()
    }
    
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
    
    func getFlickrPages(latitude: Double, longitude: Double, hostViewController: PhotoCollectionViewController) {
        
        let methodParameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.BoundingBox: bboxString(hostViewController),
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
                    
                    hostViewController.numberOfPages = pageLimit
                    
                    let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                    
                    self.getFlickrPosts(latitude, longitude: longitude, withPageNumber: randomPage, hostViewController: hostViewController)
                    
                } catch {
                    print("Error with parsing JSON. (latlon request)")
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        hostViewController.refreshCollectionButton.enabled = true
                    })
                }
            }
        }
    }
    
    func getFlickrPosts(latitude: Double, longitude: Double, withPageNumber: Int, hostViewController: PhotoCollectionViewController) {
        
        let methodParameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.BoundingBox: bboxString(hostViewController),
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
                    
                    hostViewController.posts = posts
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        
                        if hostViewController.posts.isEmpty {
                            hostViewController.textLabel.hidden = false
                        } else {
                            hostViewController.textLabel.hidden = true
                        }
                        
                        hostViewController.refreshCollectionButton.enabled = true
                        hostViewController.collectionView.reloadData()
                    })
                    
                } catch {
                    print("Error with parsing JSON. (latlonpage request)")
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        hostViewController.refreshCollectionButton.enabled = true
                    })
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
    
    private func bboxString(hostViewController: PhotoCollectionViewController) -> String {
        // ensure bbox is bounded by minimum and maximums
        let latitude = hostViewController.lat
        let longitude = hostViewController.lon
        let minimumLon = max(longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
        let minimumLat = max(latitude - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
        let maximumLon = min(longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
        let maximumLat = min(latitude + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
        
    }
}