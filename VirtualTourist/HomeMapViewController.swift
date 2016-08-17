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

class HomeMapViewController: UIViewController, UIGestureRecognizerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up gesture recognition for mapView
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(HomeMapViewController.handleTap))
        gestureRecognizer.delegate = self
        mapView.addGestureRecognizer(gestureRecognizer)
    
    }
    
    func handleTap(gestureRecognizer: UILongPressGestureRecognizer) {
        
        if gestureRecognizer.state == .Began {
            let location = gestureRecognizer.locationInView(mapView)
            let coordinate = mapView.convertPoint(location, toCoordinateFromView: mapView)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            mapView.addAnnotation(annotation)
        }
    }
    
}