//
//  CommentBubbleViewModel.swift
//  Pong
//
//  Created by Khoi Nguyen on 8/1/22.
//

import Foundation

class CommentBubbleViewModel: ObservableObject {
    @Published var comment : Comment = defaultComment
    
    // MARK: CommentVote
    func commentVote(direction: Int) -> Void {
        
        var voteToSend = 0
        if direction == comment.voteStatus {
            voteToSend = 0
        } else {
            voteToSend = direction
        }
        
        print("DEBUG: commentBubbleVM.commentVote \(voteToSend)")
        
        let parameters = CommentVoteModel.Request(vote: voteToSend)
        
        NetworkManager.networkManager.request(route: "comments/\(comment.id)/vote/", method: .post, body: parameters, successType: CommentVoteModel.Response.self) { successResponse, errorResponse in
            // MARK: Success
            DispatchQueue.main.async {
                if let successResponse = successResponse {
                    self.comment.voteStatus = successResponse.voteStatus
                }
                if let errorResponse = errorResponse {
                    print("DEBUG: \(errorResponse)")
                }
            }
        }
    }
    
    func deleteComment() {
        NetworkManager.networkManager.request(route: "comments/\(comment.id)/", method: .delete, successType: Post.self) { successResponse, errorResponse in
            DispatchQueue.main.async {
                print("DEBUG: ")
            }
        }
    }
    
    func saveComment() {
        NetworkManager.networkManager.emptyRequest(route: "comments/\(comment.id)/save/", method: .post) { successResponse, errorResponse in
            DispatchQueue.main.async {
                print("DEBUG: ")
            }
        }
    }
    
    func blockComment() {
        NetworkManager.networkManager.emptyRequest(route: "comments/\(comment.id)/block/", method: .post) { successResponse, errorResponse in
            DispatchQueue.main.async {
                print("DEBUG: ")
            }
        }
    }
    
    func reportComment() {
        NetworkManager.networkManager.emptyRequest(route: "comments/\(comment.id)/report/", method: .post) { successResponse, errorResponse in
            DispatchQueue.main.async {
                print("DEBUG: ")
            }
        }
    }
    
}
