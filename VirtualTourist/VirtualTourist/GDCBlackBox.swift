//
//  GDCBlackBox.swift
//  VirtualTourist
//
//  Created by bumblebee on 11/20/17.
//  Copyright © 2017 Victoria Yu. All rights reserved.
//

import UIKit

func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
    DispatchQueue.main.async {
        updates()
    }
}

