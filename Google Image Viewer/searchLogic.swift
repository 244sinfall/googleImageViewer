//
//  searchLogic.s/Users/dmitrijfilin/Library/Mobile Documents/com~apple~CloudDocs/Xcode/Google Image Viewer/Google Image Viewer/Google Image Viewer/ViewController.swiftwift
//  Google Image Viewer
//
//  Created by Дмитрий Филин on 21.12.2021.
//

import Foundation

enum possibleErrors: Error, CustomStringConvertible {
    case APIError, NoData, IncorrentLink, OtherError
    var description: String {
        switch self {
        case .APIError: return "API limit reached"
        case .NoData: return "No data avaliable"
        case .IncorrentLink: return "Error when generating link"
        case .OtherError: return "Check connection"
        }
    }
}

struct ImagesContainer:Decodable {
    var images_results:[ImageDataStructure]
}

struct ImageDataStructure: Decodable {
    var position: Int
    var thumbnail: URL
    var title: String
    var link: String
    var original: URL
}

struct SearchRequest {
    let apiKey = "36287cd449e544067380cfe4813ebb7205b1823dde3095de879494c3dfbf164f"
    let URLToPush: URL
    init(stringToSearch:String, pageToLoad:inout Int) throws {
        let correctStringToSearch = stringToSearch.replacingOccurrences(of: " ", with: "+").addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? stringToSearch.replacingOccurrences(of: " ", with: "+")
        let resourceFinal = "https://serpapi.com/search?q=\(correctStringToSearch)&tbm=isch&ijn=\(pageToLoad)&api_key=\(apiKey)" //PRODUCTION
        //print(resourceFinal)
        //let resourceFinal = "https://serpapi.com/search?q=\(correctStringToSearch)&tbm=isch&ijn=\(pageToLoad)" //DEBUG
        guard let URLToPush = URL(string: resourceFinal) else { throw possibleErrors.IncorrentLink }
        self.URLToPush = URLToPush
    }
    
    func getImages(completion: @escaping(Result<[ImageDataStructure], possibleErrors>) -> Void)
    {
        let dataTask = URLSession.shared.dataTask(with: URLToPush)
        { data, _, _ in
            guard let receivedData = data else { completion(.failure(.OtherError)); return }
            do
            {
                let decoder = JSONDecoder()
                let imagesGot = try decoder.decode(ImagesContainer.self, from: receivedData)
                let receiveImagesInfo = imagesGot.images_results
                completion(.success(receiveImagesInfo))
                searchPage += 1
            }
            catch
            {
                completion(.failure(.NoData))
                return
            }
        }
        dataTask.resume()
    }
}
