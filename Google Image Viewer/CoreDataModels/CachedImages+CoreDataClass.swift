//
//  CachedImages+CoreDataClass.swift
//  Google Image Viewer
//
//  Created by Дмитрий Филин on 23.12.2021.
//
//

import Foundation
import CoreData
import UIKit

@objc(CachedImages)
public class CachedImages: NSManagedObject {
    func isImageExist(link: URL) -> Data? {
        let fetchRequest: NSFetchRequest<CachedImages> = CachedImages.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "imageLink == %@", link as CVarArg)
        do {
            let fetchResults = try managedObjectContext?.fetch(fetchRequest)
            if !fetchResults!.isEmpty {
                return fetchResults!.first!.imageData
            }
            else {
                return nil
            }
        }
        catch {
            return nil
        }
    }
}
