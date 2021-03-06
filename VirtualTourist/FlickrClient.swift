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
    
    func getFlickrPages(latitude: Double, longitude: Double, hostViewController: PhotoCollectionViewController, completionHandlerForFlickrPages: (success: Bool, error: NSError?) -> Void) {
        
        print("called getFlickrPages")
        
        let methodParameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.BoundingBox: bboxString(hostViewController),
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.SquareURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback,
            Constants.FlickrParameterKeys.PerPage: Constants.FlickrParameterValues.PerPage
        ]
        
        //Clear cache to get ready to receive fresh image responses for cells
        
        Alamofire.request(.GET, flickrURL(), parameters: methodParameters)
            .validate()
            .responseJSON { response in
                switch(response.result) {
                case .Success:
                    if let data = response.data {
                        do {
                            let json = try JSON(data: data)
                            let pages = try json.int(Constants.FlickrResponseKeys.Photos, Constants.FlickrResponseKeys.Pages)
                            
                            let pageLimit = min(pages, Constants.Flickr.maxPages)
                            
                            hostViewController.numberOfPages = pageLimit
                            
                            let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                            
                            hostViewController.randomPage = randomPage
                            hostViewController.numberOfPages = pageLimit
                            
                            completionHandlerForFlickrPages(success: true, error: nil)
                            
                            //self.getFlickrPosts(latitude, longitude: longitude, withPageNumber: randomPage, hostViewController: hostViewController)
                            
                        } catch {
                            print("Error with parsing JSON. (latlon request)")
                            
                            dispatch_async(dispatch_get_main_queue(), {
                                hostViewController.indicateLoading(false)
                            })
                            
                            completionHandlerForFlickrPages(success: false, error: nil)
                        }
                    }
                case .Failure:
                    print(response.result.error)
                    dispatch_async(dispatch_get_main_queue(), {
                        hostViewController.indicateLoading(false)
                    })
                    
                    completionHandlerForFlickrPages(success: false, error: response.result.error)
            }
        }
    }
    
    func getFlickrPosts(latitude: Double, longitude: Double, withPageNumber: Int, hostViewController: PhotoCollectionViewController, completionHandlerForFlickrPosts: (success: Bool, error: NSError?) -> Void) {
        
        print("called getFlickrPosts")
        
        let methodParameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.BoundingBox: bboxString(hostViewController),
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.SquareURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback,
            Constants.FlickrParameterKeys.Page: String(withPageNumber),
            Constants.FlickrParameterKeys.PerPage: Constants.FlickrParameterValues.PerPage
        ]
        
        //Clear cache to get ready to receive fresh image responses for cells
        //NSURLCache.sharedURLCache().removeAllCachedResponses()
        
        let request = NSMutableURLRequest(URL: flickrURL())
        request.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
        
        Alamofire.request(.GET, request, parameters: methodParameters)
            .validate()
            .responseJSON { response in
                switch(response.result) {
                case .Success:
                    if let data = response.data {
                        do {
                            let json = try JSON(data: data)
                            let posts = try json.array(Constants.FlickrResponseKeys.Photos, Constants.FlickrResponseKeys.Photo).map(FlickrPost.init)
                            
                            hostViewController.posts = posts
                            print("number of posts: \(posts.count)")
                            
                            dispatch_async(dispatch_get_main_queue(), {
                                
                                if hostViewController.posts.isEmpty {
                                    hostViewController.textLabel.hidden = false
                                } else {
                                    hostViewController.textLabel.hidden = true
                                }
                                
                                hostViewController.indicateLoading(false)
                            })
                            
                            completionHandlerForFlickrPosts(success: true, error: nil)
                            
                        } catch {
                            print("Error with parsing JSON. (latlonpage request)")
                            
                            dispatch_async(dispatch_get_main_queue(), {
                                hostViewController.indicateLoading(false)
                                completionHandlerForFlickrPosts(success: false, error: response.result.error)
                            })
                        }
                    }
                case .Failure:
                    print(response.result.error)
                    dispatch_async(dispatch_get_main_queue(), {
                        hostViewController.indicateLoading(false)
                    })
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