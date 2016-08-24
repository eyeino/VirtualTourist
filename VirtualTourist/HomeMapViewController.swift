//
//  HomeMapViewController.swift
//  VirtualTourist
//
//  Created by Ian MacFarlane on 8/16/16.
//  Copyright © 2016 Ian MacFarlane. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class HomeMapViewController: UIViewController, UIGestureRecognizerDelegate, MKMapViewDelegate {
    
    let managedObjectContext = DataController.sharedInstance().managedObjectContext
    let pinFetch = NSFetchRequest(entityName: "Pin")
    
    var lat: Double = 40.0
    var lon: Double = 40.0
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var fetchedPins: [Pin]?
        //Get saved pins and add them to the mapView
        do {
            fetchedPins = try managedObjectContext.executeFetchRequest(pinFetch) as? [Pin]
        } catch {
            fatalError("Failed to fetch pins: \(error)")
        }
        
        if fetchedPins != nil, let pins = fetchedPins {
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
        
        mapView.deselectAnnotation(view.annotation!, animated: false)
        
        performSegueWithIdentifier("showPhotoCollectionForLocation", sender: view)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showPhotoCollectionForLocation") {
            let destinationVC: PhotoCollectionViewController = segue.destinationViewController as! PhotoCollectionViewController
            let pin = findPinWithCoordinates(lat, longitude: lon)
            
            destinationVC.lat = lat
            destinationVC.lon = lon
            destinationVC.pin = pin
            
        }
    }
    
    func findPinWithCoordinates(latitude: Double, longitude: Double) -> Pin? {
        
        var pin: Pin?
        let searchParameter = String(latitude) + String(longitude)
        let fetch = NSFetchRequest(entityName: "Pin")
        fetch.predicate = NSPredicate(format: "id == %@", searchParameter)
        
        let moc = self.managedObjectContext
        do {
            let fetchedPins = try moc.executeFetchRequest(fetch) as! [Pin]
            pin = fetchedPins[0]
            
            print("FOUND PIN: \(pin)")
        } catch {
            print("Error fetching pin for lon: \(longitude) and lat: \(latitude)")
        }
        
        return pin
    }
    
}