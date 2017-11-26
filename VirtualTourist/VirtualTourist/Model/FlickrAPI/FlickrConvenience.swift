//
//  FlickrConvenience.swift
//  VirtualTourist
//
//  Created by bumblebee on 11/18/17.
//  Copyright © 2017 Victoria Yu. All rights reserved.
//

import Foundation
import CoreData

extension FlickrClient {
    
    // MARK: Download Photos from Flickr and save them
    func downloadPhotos(_ pin: Pin, _ pageNumber: Int, completionHandler: @escaping (_ success: Bool, _ error: NSError?) -> Void) {
        
        let parameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.Latitude: pin.latitude,
            Constants.FlickrParameterKeys.Longitude: pin.longitude,
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback,
            Constants.FlickrParameterKeys.Page: pageNumber,
            Constants.FlickrParameterKeys.PerPage: Constants.FlickrParameterValues.PerPageLimit] as [String:AnyObject]
        
        let task = taskForGETMethod(parameters) { (results, error) in
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = results![Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else {
                completionHandler(false, error)
                return
            }
            
            /* GUARD: Is the "photos" key in our result? */
            guard let photosDictionary = results![Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                completionHandler(false, error)
                return
            }
            
            /* GUARD: Is the "photo" key in photosDictionary? */
            guard let photosArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                completionHandler(false, error)
                return
            }
            
            performUIUpdatesOnMain {
                
                if photosArray.count > 0 {
                    for photoUrl in photosArray {
                        
                        /* GUARD: Does our photo have a key for 'url_m'? */
                        guard let imageUrlString = photoUrl[Constants.FlickrResponseKeys.MediumURL] as? String else {
                            completionHandler(false, error)
                            return
                        }
                        // Create Photo entity and insert it into context
                        let photo:Photo = NSEntityDescription.insertNewObject(forEntityName: "Photo", into: AppDelegate.stack.context) as! Photo
                        photo.imageUrl = imageUrlString
                        // Add photo to the pin
                        photo.pin = pin
                    }
                }
                AppDelegate.stack.save()
                completionHandler(true, nil)
            }
        }
        task.resume()
    }
    
    // MARK: Convert image URL to Data
    
    func getImageDataFromUrl(_ urlString: String, completionHandlerForGetImageData: @escaping (_ result: Data?, _ error: NSError?) -> Void) {
        
        let session = URLSession.shared
        guard let url = URL(string: urlString) else { return }
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request) { (data, reponse, error) in
            
            func sendError(_ error: String) {
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForGetImageData(nil, NSError(domain: "taskForGetDataFromUrl", code: 1, userInfo: userInfo))
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                sendError("There was an error with your request: \(error!)")
                return
            }
            completionHandlerForGetImageData(data, nil)
        }
        task.resume()
    }
}
