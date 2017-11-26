//
//  Pin+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by bumblebee on 11/18/17.
//  Copyright © 2017 Victoria Yu. All rights reserved.
//
//

import Foundation
import CoreData


extension Pin {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Pin> {
        return NSFetchRequest<Pin>(entityName: "Pin")
    }

    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var page: Int32
    @NSManaged public var photos: NSSet?

}
