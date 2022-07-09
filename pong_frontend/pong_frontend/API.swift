//
//  API.swift
//  pong_frontend
//
//  Created by Khoi Nguyen on 6/9/22.
//

import Foundation

enum AuthenticationError: Error {
    case invalidCredentials
    case custom(errorMessage: String)
}

enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
}

struct LoginRequestBody: Codable {
    let email_or_username: String
    let password: String
}

struct LoginResponse: Codable {
    let token: String?
    let message: String?
    let success: Bool?
}

struct PostRequestBody: Codable {
    let title: String
}

struct PostRequestResponse: Codable {
    let id: Int
    let user: Int
    let title: String
    let created_at: String
    let updated_at: String
    let image: String?
    let num_comments: Int
    let comments: [Comment]
    let score: Int
    let time_since_posted: String
}

struct OTPStartRequestBody: Codable {
    let phone: String
}

struct OTPStartResponseBody: Codable {
    let new_user: Bool?
    let phone: String?
}

struct OTPVerifyRequestBody: Codable {
    let phone: String
    let code: String
}

// token : String, new_user : Bool, code_expire : Bool, code_incorrect : Bool
struct OTPVerifyResponseBody: Codable {
    let token: String?
    let email_unverified: Bool?
    let code_expire: Bool?
    let code_incorrect: Bool?
}

struct VerifyEmailRequestBody: Codable {
    let phone: String
    let email: String
}

struct VerifyEmailResponseBody: Codable {
    let token: String?
    
}

class API: ObservableObject {
    var root: String = "http://localhost:8005/api/"
    @Published var posts: [Post] = []
    
    func getPosts() {
        print("DEBUG: API getPosts")
        
        guard let token = DAKeychain.shared["token"] else { return } // Fetch
        
        // url handler
        guard let url = URL(string: "\(root)" + "post/") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Token \(token)", forHTTPHeaderField: "Authorization")
        
        // task handler. [weak self] prevents memory leaks
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            
            guard let data = data, error == nil else { return }
            
            // convert to json
            do {
                let posts = try JSONDecoder().decode([Post].self, from: data)
                DispatchQueue.main.async {
                    self?.posts = posts
                }
            } catch {
                print("DEBUG: \(error)")
            }
        }
        // activates api call
        task.resume()
    }
    
    func otpStart(phone: String, completion: @escaping (Result<Bool, AuthenticationError>) -> Void) {
        print("DEBUG: API otpStart \(phone)")
        
        // change URL to real login
        guard let url = URL(string: "\(root)" + "otp-start/") else {
            completion(.failure(.custom(errorMessage: "URL is not correct")))
            return
        }
        
        let body = OTPStartRequestBody(phone: phone)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(body)
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            guard let data = data, error == nil else {
                completion(.failure(.custom(errorMessage: "No data")))
                return
            }
            
            guard let otpStartResponse = try? JSONDecoder().decode(OTPStartResponseBody.self, from: data) else {
                completion(.failure(.invalidCredentials))
                return
            }
            
            guard let new_user = otpStartResponse.new_user else {
                completion(.failure(.invalidCredentials))
                return
            }
            
            completion(.success(new_user))
            
        }.resume()
    }
    
    func otpVerify(phone: String, code: String, completion: @escaping (Result<OTPVerifyResponseBody, AuthenticationError>) -> Void) {
        // change URL to real login
        guard let url = URL(string: "\(root)" + "otp-verify/") else {
            completion(.failure(.custom(errorMessage: "URL is not correct")))
            return
        }
        
        let body = OTPVerifyRequestBody(phone: phone,code: code)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(body)
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            guard let data = data, error == nil else {
                completion(.failure(.custom(errorMessage: "No data")))
                return
            }
            
            guard let otpVerifyResponse = try? JSONDecoder().decode(OTPVerifyResponseBody.self, from: data) else {
                completion(.failure(.invalidCredentials))
                return
            }
            
            print("DEBUG: API otpVerifyResponse is \(otpVerifyResponse)")
            
            // token : String, new_user : Bool, code_expire : Bool, code_incorrect : Bool
            if let responseDataContent = otpVerifyResponse.token {
                print("DEBUG: API Token is \(responseDataContent)")
                completion(.success(otpVerifyResponse))
                return
            }
            
            if let responseDataContent = otpVerifyResponse.email_unverified {
                print("DEBUG: API email_unverified is \(responseDataContent)")
                completion(.success(otpVerifyResponse))
                return
            }
            
            if let responseDataContent = otpVerifyResponse.code_expire {
                print("DEBUG: code_expire is \(responseDataContent)")
                completion(.success(otpVerifyResponse))
                return
            }
            
            if let responseDataContent = otpVerifyResponse.code_incorrect {
                print("DEBUG: code_incorrect is \(responseDataContent)")
                completion(.success(otpVerifyResponse))
                return
            }
            
            print("DEBUG: API \(otpVerifyResponse)")
            completion(.failure(.custom(errorMessage: "Broken")))
            
        }.resume()
    }
    
    func verifyEmail(phone: String, email: String, completion: @escaping (Result <String, AuthenticationError>) -> Void ) {
        guard let url = URL(string: "\(root)" + "verify-user/") else {
            completion(.failure(.custom(errorMessage: "URL is not correct")))
            return
        }
        
        let body = VerifyEmailRequestBody(phone: phone, email: email)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(body)
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
                completion(.failure(.custom(errorMessage: "No data")))
                return
            }
            
            guard let verifyEmailResponse = try? JSONDecoder().decode(VerifyEmailResponseBody.self, from: data) else {
                completion(.failure(.invalidCredentials))
                return
            }
            
            print("DEBUG: API otpVerifyResponse is \(verifyEmailResponse)")
            
            // token : String, new_user : Bool, code_expire : Bool, code_incorrect : Bool
            if let responseDataContent = verifyEmailResponse.token {
                print("DEBUG: API Token is \(responseDataContent)")
                completion(.success(verifyEmailResponse.token!))
                return
            }
            
            
            print("DEBUG: API \(verifyEmailResponse.token!)")
            completion(.failure(.custom(errorMessage: "new_user not returned. Consider code_expire or code_incorrect")))
            
        }.resume()
        
    }
}
