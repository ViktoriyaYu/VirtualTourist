//
//  Photo+CoreDataClass.swift
//  VirtualTourist
//
//  Created by bumblebee on 11/18/17.
//  Copyright © 2017 Victoria Yu. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Photo)
public class Photo: NSManagedObject {
    // MARK: Initializer
    
//    convenience init(imageUrl: String, imageData: NSData, pin: Pin, context: NSManagedObjectContext) {
//
//        // An EntityDescription is an object that has access to all
//        // the information you provided in the Entity part of the model
//        // you need it to create an instance of this class.
//        if let ent = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
//            self.init(entity: ent, insertInto: context)
//            self.imageUrl = imageUrl
//            self.pin = pin
//            self.imageData = imageData
//            print("PhotoClass init: \(imageUrl)")
//        } else {
//            fatalError("Unable to find Entity name!")
//        }
//    }
}
