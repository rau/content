//
//  VerifyEmailRequestBody.swift
//  Pong
//
//  Created by Khoi Nguyen on 7/12/22.
//

import Foundation

struct VerifyEmailRequestBody: Encodable {
    let phone: String
    let email: String
}

