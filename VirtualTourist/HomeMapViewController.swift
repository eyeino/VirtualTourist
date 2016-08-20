//
//  HomeMapViewController.swift
//  VirtualTourist
//
//  Created by Ian MacFarlane on 8/16/16.
//  Copyright © 2016 Ian MacFarlane. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class HomeMapViewController: UIViewController, UIGestureRecognizerDelegate, MKMapViewDelegate {
    
    let managedObjectContext = DataController.sharedInstance().managedObjectContext
    let pinFetch = NSFetchRequest(entityName: "Pin")
    var fetchedPins: [Pin]?
    
    var lat: Double = 34.6937
    var lon: Double = 135.5022
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Get saved pins and add them to the mapView
        do {
            fetchedPins = try managedObjectContext.executeFetchRequest(pinFetch) as? [Pin]
        } catch {
            fatalError("Failed to fetch employees: \(error)")
        }
        
        if let pins = fetchedPins {
            var annotations = [MKPointAnnotation()]
            for pin in pins {
                guard let lat = pin.lat as? Double, let lon = pin.lon as? Double else {
                    break
                }
                
                let annotation = MKPointAnnotation()
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                annotation.coordinate = coordinate
                annotations.append(annotation)
            }
            mapView.addAnnotations(annotations)
        }
        
        // Set up gesture recognition for mapView
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(HomeMapViewController.handleTap))
        gestureRecognizer.delegate = self
        mapView.addGestureRecognizer(gestureRecognizer)
        
        mapView.delegate = self
    
    }
    
    func handleTap(gestureRecognizer: UILongPressGestureRecognizer) {
        
        if gestureRecognizer.state == .Began {
            let location = gestureRecognizer.locationInView(mapView)
            let coordinate = mapView.convertPoint(location, toCoordinateFromView: mapView)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            
            mapView.addAnnotation(annotation)
            
            _ = Pin(latitude: coordinate.latitude, longitude: coordinate.longitude, context: managedObjectContext)
            
            do {
                try managedObjectContext.save()
            } catch {
                fatalError("Failure to save context: \(error)")
            }
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = UIColor.blueColor()
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    // This delegate method is implemented to respond to taps
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        lat = view.annotation!.coordinate.latitude
        lon = view.annotation!.coordinate.longitude
        
        mapView.deselectAnnotation(view.annotation!, animated: true)
        
        performSegueWithIdentifier("showPhotoCollectionForLocation", sender: view)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showPhotoCollectionForLocation") {
            let destinationVC: PhotoCollectionViewController = segue.destinationViewController as! PhotoCollectionViewController
            destinationVC.lat = lat
            destinationVC.lon = lon
        }
    }
    
}