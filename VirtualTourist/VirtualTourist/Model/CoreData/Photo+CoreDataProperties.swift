//
//  Photo+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by bumblebee on 11/18/17.
//  Copyright © 2017 Victoria Yu. All rights reserved.
//
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo")
    }

    @NSManaged public var imageUrl: String?
    @NSManaged public var imageData: NSData?
    @NSManaged public var pin: Pin?

}
