//
//  CommentVoteModel.swift
//  Pong
//
//  Created by Khoi Nguyen on 8/8/22.
//

import Foundation

struct CommentVoteModel {
    
    struct Request: Encodable {
        let commentId: String
        let vote: Int
    }
    
    struct Response: Decodable {
        let voteStatus: Int?
        let error: String?
    }
}
