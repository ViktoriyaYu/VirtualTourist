//
//  PhotoCollectionViewController.swift
//  VirtualTourist
//
//  Created by bumblebee on 11/18/17.
//  Copyright © 2017 Victoria Yu. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoCollectionViewController: UIViewController, UICollectionViewDelegate, MKMapViewDelegate, NSFetchedResultsControllerDelegate, UICollectionViewDataSource {
    
    // MARK: Properties
    var tappedPin: Pin!
    var photos = [Photo]()
    var selectedIndexes = [IndexPath]() // array keeps all of the indexPaths for cells that are "selected".
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    var pageNumber = 0
    
    // MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var noImagesLabel: UILabel!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Delegates
        collectionView.delegate = self
        collectionView.dataSource = self
        mapView.delegate = self
        
        // Search for (fetch) photos for the tapped pin
        executeSearch()
        // Reload collection view
        reloadPhotos()
        
        // Implement flowLayout
        let space:CGFloat = 3.0
        let dimensionW = (view.frame.size.width - (2 * space)) / 3.0
        let dimensionH = (view.frame.size.height - (2 * space)) / 3.0
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimensionW, height: dimensionH)
        // Show pin annotation on the map view
        zoomedMapView()
        // Update New collection button
        updateNewColButton()
        
    }
    
    // Show a placemark on a map. Zoom the map into an appropriate region.
    func zoomedMapView() {
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2DMake(tappedPin.latitude, tappedPin.longitude)
        DispatchQueue.main.async {
            self.mapView.addAnnotation(annotation)
            self.mapView.setRegion(MKCoordinateRegionMake(annotation.coordinate, MKCoordinateSpanMake(0.5, 0.5)), animated: true)
        }
    }
    // Create fetch results controller for the tappedPin and try to get data
    func executeSearch() {
        let fr: NSFetchRequest<Photo> = Photo.fetchRequest()
        fr.sortDescriptors = []
        fr.predicate = NSPredicate(format: "pin = %@", tappedPin)
        let frController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: AppDelegate.stack.context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController = frController
        // Perform fetch
        do {
            try fetchedResultsController.performFetch()
        } catch let e as NSError {
            print("Error while trying to perform a search: \n\(e)\n\(fetchedResultsController)")
        }
    }
    
    // Get fetch results and if empty download photos and reload collection view
    func reloadPhotos() {
        photos = fetchedResultsController.fetchedObjects!
        if photos.isEmpty {
            // Download photos from Flickr
            FlickrClient.sharedInstance().downloadPhotos(tappedPin, pageNumber, completionHandler: { (success, error) in
                if success {
                    performUIUpdatesOnMain {
                        // Reload collection view
                        self.collectionView.reloadData()
                    }
                } else {
                    self.showAlert(errorMsg: "Couldn't download photos")
                }
            })
        } else {
            collectionView.reloadData()
        }
        pageNumber += 1
    }
    
    // MARK: CollectionView functions
    
    // Get number of items in section
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sections = fetchedResultsController.sections![section]
        let numberOfItems = sections.numberOfObjects
        // HIde no images label if found more than 0 items
        if numberOfItems > 0 {
            noImagesLabel.isHidden = true
        }
        return numberOfItems
    }
    
    // Configure and populate the cell
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Configure the cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoCollectionViewCell
        cell.activityIndicator.startAnimating()
        cell.photoView.image = UIImage(named: "placeholder")
        
        let photo = fetchedResultsController.object(at: indexPath)
        // Check if there is image data
        if photo.imageData != nil {
            performUIUpdatesOnMain {
                cell.activityIndicator.stopAnimating()
                cell.photoView.image = UIImage(data: photo.imageData! as Data)
            }
        } else {
            // Check if photo has image url stored
            if let imageUrl = photo.imageUrl {
                // Convert image url to data
                FlickrClient.sharedInstance().getImageDataFromUrl(imageUrl, completionHandlerForGetImageData: { (results, error) in
                    guard let imageData = results else {
                        self.showAlert(errorMsg: "No image data found in reesults")
                        return
                    }
                    performUIUpdatesOnMain {
                        photo.imageData = imageData as NSData
                        cell.activityIndicator.stopAnimating()
                        cell.photoView.image = UIImage(data: photo.imageData! as Data)
                        //AppDelegate.stack.save()
                    }
                })
            }
            else {
                // Get data from flickr
                executeSearch()
            }
        }
        
        // If the cell is "selected", its color panel is grayed out
        if let _ = selectedIndexes.index(of: indexPath) {
            cell.photoView.alpha = 0.05
        } else {
            cell.photoView.alpha = 1.0
        }
        return cell
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("in collectionView(_:didSelectItemAtIndexPath)")
        // Whenever a cell is tapped we will toggle its presence in the selectedIndexes array
        if let index = selectedIndexes.index(of: indexPath) {
            selectedIndexes.remove(at: index)
        } else {
            selectedIndexes.append(indexPath)
        }
        // update the new collection button
        updateNewColButton()
    }
    
    // MARK: New Collection(/Delete selected) button
    
    @IBAction func newCollectionTapped(_ sender: Any) {
        if selectedIndexes.isEmpty {
            // get new collection
            getNewPhotoCollection()
        } else {
            // delete selected photos
            deleteSelectedPhotos()
            collectionView.reloadData()
        }
    }
    
    func getNewPhotoCollection() {
        for photo in photos {
            AppDelegate.stack.context.delete(photo)
        }
        AppDelegate.stack.save()
        reloadPhotos()
    }
    
    func deleteSelectedPhotos() {
        var selectedPhotos = [Photo]()
        for indexPath in selectedIndexes {
            selectedPhotos.append(fetchedResultsController.object(at: indexPath))
        }
        
        for photo in selectedPhotos {
            AppDelegate.stack.context.delete(photo)
        }
        AppDelegate.stack.save()
        selectedIndexes = [IndexPath]()
    }
    
    func updateNewColButton() {
        if selectedIndexes.count > 0 {
            newCollectionButton.setTitle("Delete Selected", for: .normal)
        } else {
            newCollectionButton.titleLabel?.text = "New Collection"
        }
    }
}
