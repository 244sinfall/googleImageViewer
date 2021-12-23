//
//  ViewController.swift
//  Google Image Viewer
//
//  Created by Дмитрий Филин on 20.12.2021.
//

import UIKit
import CoreData
import WebKit


var selectedImage: ImageDataStructure? // global to track what image is selected from collection view

var latestQuerry: String? // global to track state of searchbar

var searchPage = 0 // inout var that goes to searchLogic and add new results to current search

class WebpreviewViewController: UIViewController, WKUIDelegate {
    // Just a view controller with full scale webview, triggered by open source button
    var webViewURL: URL?
    @IBOutlet weak var webViewControl: WKWebView!
    override func viewDidLoad() {
        DispatchQueue.main.async {
            super.viewDidLoad()
            self.webViewControl.uiDelegate = self
            self.webViewControl.load(URLRequest(url: self.webViewURL!))
        }

    }
}

class FullscreenViewController: UIViewController {
    // full screen view, triggered by a click on collectionviewcell
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var structure: [ImageDataStructure]?
    var structureIndex: Int?
    @IBOutlet weak var fullscreenImage: UIImageView!
    
    @IBAction func nextButton(_ sender: Any) {
        if structureIndex == structure!.count-1 {
            structureIndex = 0
            selectedImage = structure![0]
            loadFullscreenImage()
        }
        else {
            structureIndex! += 1
        selectedImage =  structure![structureIndex!]
            loadFullscreenImage() }
    }
    
    @IBAction func prevButton(_ sender: UIBarButtonItem) {
        if structureIndex == 0 {
            structureIndex
            = structure!.count-1
            selectedImage = structure![structure!.count-1]
            loadFullscreenImage()
        }
        else {
            structureIndex! -= 1
            selectedImage =  structure![structureIndex!] // TO DO PROPERLY
            loadFullscreenImage() }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.async {
            self.loadFullscreenImage()
        }
    }
    // it takes a selected image and loads full screen. if cached, it takes from cache, if not - downloads from imagestruct
    func loadFullscreenImage()
    {
        let container = CachedImages(context: context)
        DispatchQueue.main.async {
            if let data = container.isImageExist(link: selectedImage!.original)
            {
                self.fullscreenImage.image = UIImage(data: data)
            }
            else {
                DispatchQueue.main.async {
                    if let data = try? Data(contentsOf: selectedImage!.original) {
                        let toCacheImage = CachedImages(context: self.context)
                        toCacheImage.imageData = data
                        toCacheImage.imageLink = selectedImage!.original
                        self.fullscreenImage.image = UIImage(data: data)
                    }
                    else {
                        self.fullscreenImage.image = UIImage(named: "defaultPlaceholder")
                    }
                }
                do {
                    try self.context.save() }
                catch { self.context.rollback() }
            }
        }

    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showWebview" {
            if let destination = segue.destination as? WebpreviewViewController {
                destination.webViewURL = URL(string: selectedImage!.link)
            }
        }
    }
}

class ViewController: UIViewController, UISearchBarDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    var structureIndex: Int? // I HAVENT FOUND ANY OTHER WAY TO TRANSFER IMAGERESULT INDEX LOL
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext // it is very complicated, i googled it
    var imagesResult: [ImageDataStructure] = []
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "showImageDetails" {
                if let destination = segue.destination as? FullscreenViewController {
                    DispatchQueue.main.async {
                        destination.structure = self.imagesResult
                        destination.structureIndex = self.structureIndex
                    }
                }
            }
    }
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var searchResultFlowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var resultCollectionView: ResultCollectionView!
    
    var statusText: String?
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        resultCollectionView.delegate = self
        resultCollectionView.dataSource = self
        searchResultFlowLayout.itemSize = CGSize(width: CGFloat(view.frame.width/4)-10, height: CGFloat(view.frame.width/4)-10)
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            if imagesResult.isEmpty && imagesResult.isEmpty {
                statusLabel.text = "Result will appear here..."
            }
        }
        else {
            statusLabel.text = ""
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if !searchBar.text!.trimmingCharacters(in: .whitespaces).isEmpty {
            if !statusLabel.text!.isEmpty { statusLabel.text = "" }
            searchPage = 0
            if latestQuerry == searchBar.text {         searchBar.endEditing(true); return }
            else {
                latestQuerry = searchBar.text
                imagesResult = []
                resultCollectionView.reloadData()
                do {
                    let searchObject = try SearchRequest(stringToSearch: searchBar.text!, pageToLoad: &searchPage)
                    searchObject.getImages { result in
                        switch result {
                    case .failure(let error):
                            DispatchQueue.main.async { [self] in
                                statusLabel.text = error.description
                            }
                    case .success(let resultJSON):
                            self.imagesResult = resultJSON
                            DispatchQueue.main.async { [self] in
                            self.resultCollectionView.reloadData()
                            }
                        }
                    }
                }
                catch {
                    statusLabel.text = "Link gen problem"
                    return
                }
            }
            
        }
        else {
            searchBar.text = ""
            statusLabel.text = "Result will appear here..."
        }
            
        searchBar.endEditing(true)
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        DispatchQueue.main.async {
            selectedImage = self.imagesResult[indexPath.item]
            self.structureIndex = indexPath.item
        }
        
    }
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {

        let numberOfCell: CGFloat = 4   //you need to give a type as CGFloat
        let cellWidth = view.frame.width / numberOfCell
        return CGSize(width: cellWidth, height: cellWidth)
    }
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.item == imagesResult.count-1 && imagesResult.count != 0 {
            let searchObject = try! SearchRequest(stringToSearch: latestQuerry ?? "", pageToLoad: &searchPage)
            searchObject.getImages { result in
                switch result {
            case .failure(_):
                return
            case .success(let resultJSON):
                    self.imagesResult.append(contentsOf: resultJSON)
                    DispatchQueue.main.async {
                        self.resultCollectionView.reloadItems(at: [indexPath.appending(IndexPath(item: self.imagesResult.count - resultJSON.count, section: 0))])
                    }

                }
            }
        }
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //returns amount of collectionviewcells
        return imagesResult.count // debug
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // sets the collectionviewcell appearence
        let container = CachedImages(context: context)
        let resultCell = collectionView.dequeueReusableCell(withReuseIdentifier: "resultCell", for: indexPath) as! CollectionViewCell
        resultCell.thumbnailPlace.image = UIImage(named: "defaultPlaceholder")
        if imagesResult.count > 0 {
            if let data = container.isImageExist(link: imagesResult[indexPath.item].thumbnail)
            {
                resultCell.thumbnailPlace.image = UIImage(data: data)
            }
            else {
                DispatchQueue.global().async {
                    let data = try? Data(contentsOf: self.imagesResult[indexPath.item].thumbnail)
                    let toCacheImage = CachedImages(context: self.context)
                    toCacheImage.imageData = data!
                    toCacheImage.imageLink = self.imagesResult[indexPath.item].thumbnail
                    DispatchQueue.main.async {
                        resultCell.thumbnailPlace.image = UIImage(data: data!)
                    }
                }
                do {
                    try context.save()
                }
                catch {
                    context.rollback()
                }
            }
        }
        return resultCell
    }
}


