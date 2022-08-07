//
//  FeedViewModel.swift
//  pong_frontend
//
//  Created by Khoi Nguyen on 6/9/22.
//
import Foundation
import SwiftUI
import Alamofire

enum FeedFilter: String, CaseIterable, Identifiable {
    case top, hot, recent
    var id: Self { self }
    
    var title: String {
        switch self {
        case .top: return "Top"
        case .hot: return "Hot"
        case .recent: return "Recent"
        }
    }
}

// MARK: Swipe Direction
enum SwipeDirection{
    case up
    case down
    case none
}

class FeedViewModel: ObservableObject {
    @Published var selectedFeedFilter : FeedFilter = .hot
    @Published var school = "Boston University"
    @Published var isShowingNewPostSheet = false
    @Published var topPostsInitalOpen : Bool = true
    @Published var hotPostsInitalOpen : Bool = true
    @Published var recentPostsInitalOpen : Bool = true
    @Published var topPosts : [Post] = []
    @Published var hotPosts : [Post] = []
    @Published var recentPosts : [Post] = []
    
    // MARK: SwipeHiddenHeader
    // MARK: View Properties
    @Published var headerHeight: CGFloat = 0
    @Published var headerOffset: CGFloat = 0
    @Published var lastHeaderOffset: CGFloat = 0
    @Published var headerDirection: SwipeDirection = .none
    // MARK: Shift Offset Means The Value From Where It Shifted From Up/Down
    @Published var headerShiftOffset: CGFloat = 0
    
    // MARK: DynamicTabIndicator
    // MARK: View Properties
    @Published var tabviewOffset: CGFloat = 0
    @Published var tabviewIsTapped: Bool = false
    
    // MARK: Tab Offset
    func tabOffset(size: CGSize,padding: CGFloat)->CGFloat{
        return (-tabviewOffset / size.width) * ((size.width - padding) / CGFloat(FeedFilter.allCases.count))
    }
    
    // MARK: Tab Index
    func indexOf(tab: FeedFilter)->Int{
        if tab == .top {
            return 0
        } else if tab == .hot {
            return 1
        } else if tab == .recent {
            return 2
        } else {
            return 1
        }
    }
    
    // MARK: API SHIT
    func getPosts(selectedFeedFilter : FeedFilter) {
        if selectedFeedFilter == .top {
            self.topPostsInitalOpen = false
        } else if selectedFeedFilter == .hot {
            self.hotPostsInitalOpen = false
        } else if selectedFeedFilter == .recent {
            self.recentPostsInitalOpen = false
        }
        
        guard let token = DAKeychain.shared["token"] else { return }

        let url_to_use: String
        if selectedFeedFilter == .recent {
            url_to_use = "\(API().root)post/?sort=new"
        } else if selectedFeedFilter == .top {
            url_to_use = "\(API().root)post/?sort=top"
        } else {
            url_to_use = "\(API().root)post/?sort=old"
        }
        print("DEBUG: feedVM.getPosts url \(url_to_use)")
        
        guard let url = URL(string: url_to_use) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Token \(token)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data, error == nil else { return }

            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let posts = try decoder.decode([Post].self, from: data)
                
//                print("DEBUG: feedVM.getPosts posts \(posts)")
                DispatchQueue.main.async {
                    if selectedFeedFilter == .hot {
                        self?.hotPosts = posts
                    } else if selectedFeedFilter == .recent {
                        self?.recentPosts = posts
                    } else if selectedFeedFilter == .top {
                        self?.topPosts = posts
                    }
                }
            } catch {
//                print("DEBUG: feedVM.getPosts \(error)")
            }
        }
        task.resume()
    }

    func getPostsAlamofire(selectedFilter: FeedFilter) {
        let url_to_use: String
        if selectedFilter == .top {
            topPostsInitalOpen = true
            url_to_use = "\(API().root)post/?sort=top"
        } else if selectedFilter == .hot {
            hotPostsInitalOpen = true
            url_to_use = "\(API().root)post/?sort=top"
        } else if selectedFilter == .recent {
            recentPostsInitalOpen = true
            url_to_use = "\(API().root)post/?sort=new"
        } else {
            url_to_use = "\(API().root)post/?sort=old"
        }

        let method = HTTPMethod.get
        let headers: HTTPHeaders = [
            "Authorization": "Token \(String(describing: DAKeychain.shared["token"]))",
            "Content-Type": "application/x-www-form-urlencoded"
        ]

        AF.request(url_to_use, method: method, headers: headers).responseDecodable(of: Post.self) { response in
            guard let posts = response.value else { return }
//            if selectedFilter == .hot {
//                self!.hotPosts = posts
//            } else if selectedFilter == .recent {
//                self!.recentPosts = posts
//            } else if selectedFilter == .top {
//                self!.topPosts = posts
//            }
            debugPrint(posts)
        }
    }
    
    // this logic should probably go into feedviewmodel where tapping on a post calls an API to get updated post information regarding a post
    func readPost(postId: String, completion: @escaping (Result<Post, AuthenticationError>) -> Void) {
        
        
        guard let token = DAKeychain.shared["token"] else { return }
        guard let url = URL(string: "\(API().root)post/\(postId)/") else {
            completion(.failure(.custom(errorMessage: "URL is not correct")))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Token \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
                completion(.failure(.custom(errorMessage: "No data")))
                return
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            guard let postResponse = try? decoder.decode(Post.self, from: data) else {
                completion(.failure(.custom(errorMessage: "Decode failure")))
                return
            }
            DispatchQueue.main.async {
                // replace the local post
                if let index = self.hotPosts.firstIndex(where: {$0.id == postId}) {
                    self.hotPosts[index] = postResponse
                }
                if let index = self.recentPosts.firstIndex(where: {$0.id == postId}) {
                    self.recentPosts[index] = postResponse
                }
                if let index = self.topPosts.firstIndex(where: {$0.id == postId}) {
                    self.topPosts[index] = postResponse
                }
            }
            
            completion(.success(postResponse))
        }.resume()
    }
}
