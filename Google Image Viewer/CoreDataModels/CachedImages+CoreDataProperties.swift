//
//  CachedImages+CoreDataProperties.swift
//  Google Image Viewer
//
//  Created by Дмитрий Филин on 23.12.2021.
//
//

import Foundation
import CoreData


extension CachedImages {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CachedImages> {
        return NSFetchRequest<CachedImages>(entityName: "CachedImages")
    }

    @NSManaged public var imageLink: URL?
    @NSManaged public var imageData: Data?

}

extension CachedImages : Identifiable {

}
