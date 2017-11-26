//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by bumblebee on 11/17/17.
//  Copyright © 2017 Victoria Yu. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate {
    
    // MARK: Outlets
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deletePinsLabel: UILabel!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet var longPressRecognizer: UILongPressGestureRecognizer!
    
    // MARK: Properties
    
    var pins = [Pin]()
    var tappedPin: Pin?
    var editMode: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        deletePinsLabel.isHidden = true
        mapView.delegate = self
        // Load already placed pins
        fetchPins()
    }
    
    // Get pins from core data main context and add annotation to the map for each pin
    func fetchPins() {
        
        let fr: NSFetchRequest<Pin> = Pin.fetchRequest()
        pins = try! AppDelegate.stack.context.fetch(fr)
        var annotations = [MKPointAnnotation]()
        for pin in pins {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
            annotations.append(annotation)
        }
        performUIUpdatesOnMain {
            self.mapView.addAnnotations(annotations)
        }
    }
    
    // MARK: Actions
    
    // Change edit mode when Edit pressed
    @IBAction func editPinsPressed(_ sender: Any) {
        editMode = !editMode
        setEditMode(editMode)
    }
    
    // Add pin after long press
    @IBAction func longTap(_ sender: UILongPressGestureRecognizer) {
        
        // Disable long press
        if sender.state != .began { return }
        // Get and convert the coordinates
        let tapPoint = sender.location(in: mapView)
        let coordinate = mapView.convert(tapPoint, toCoordinateFrom: mapView)
        // Create and add annotation
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        // Create a pin
        let pin = NSEntityDescription.insertNewObject(forEntityName: "Pin", into: AppDelegate.stack.context) as! Pin
        pin.latitude = annotation.coordinate.latitude
        pin.longitude = annotation.coordinate.longitude
        // Save it to core data
        AppDelegate.stack.save()
        // Add to pins array
        pins.append(pin)
        // Add pin's annotation to the map
        mapView.addAnnotation(annotation)
    }
    
    // MARK: MapView functions
    
    // Turn off callout accessory view
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    // Check pin, edit mode and delete or segue
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let annotation = view.annotation
        for pin in pins {
            print("ARRAY: \(pins)")
            if annotation?.coordinate.latitude == pin.latitude && annotation?.coordinate.longitude == pin.longitude {
                tappedPin = pin
                if editMode {
                    // Delete the pin from core data and map, save
                    performUIUpdatesOnMain {
                        // Delete tapped pin
                        AppDelegate.stack.context.delete(self.tappedPin!)
                        self.mapView.removeAnnotation(annotation!)
                        // Save to context
                        AppDelegate.stack.save()
                    }
                } else {
                    // Segue to collection view
                    self.performSegue(withIdentifier: "ShowPhotos", sender: self.tappedPin)
                    mapView.deselectAnnotation(view.annotation, animated: true)
                }
            }
        }
    }
    
    // Prepare for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowPhotos" {
            let vc = segue.destination as! PhotoCollectionViewController
            // Pass the pin info to use in the next vc
            vc.tappedPin = sender as! Pin
        }
    }
    
    // MARK: Helpers
    
    func setEditMode(_ on: Bool) {
        longPressRecognizer.isEnabled = !on
        deletePinsLabel.isHidden = !on
        if on {
            editButton.title = "Done"
        } else {
            editButton.title = "Edit"
        }
        editMode = on
    }
}

extension UIViewController {
    func showAlert(errorMsg: String) {
        // Notify the user if the post fails
        let errorAlert = UIAlertController(title: "ERROR", message: errorMsg, preferredStyle: .alert)
        errorAlert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        self.present(errorAlert, animated: true, completion: nil)
    }
}
