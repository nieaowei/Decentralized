////
////  NetworkMgr.swift
////  BTCt
////
////  Created by Nekilc on 2024/5/22.
////
//
//import Foundation
//import Combine
//import SwiftUI
//import Foundation
//
//class NetworkManager {
//    
//    // 单例模式
//    static let shared = NetworkManager()
//    
//    private init() {}
//    
//    // 枚举定义请求方法
//    enum HTTPMethod: String {
//        case GET
//        case POST
//        case PUT
//        case DELETE
//    }
//    
//    // 定义错误类型
//    enum NetworkError: Error {
//        case invalidURL
//        case noData
//        case decodingError
//    }
//    
//    // 泛型方法用于发送请求并解析 JSON 响应
//    func request<T: Decodable>(urlString: String, method: HTTPMethod = .GET, parameters: [String: Any]? = nil, completion: @escaping (Result<T, NetworkError>) -> Void) {
//        
//        // 创建 URL
//        guard let url = URL(string: urlString) else {
//            completion(.failure(.invalidURL))
//            return
//        }
//        
//        // 创建 URLRequest
//        var request = URLRequest(url: url)
//        request.httpMethod = method.rawValue
//        
//        // 如果有参数，设置请求体
//        if let parameters = parameters {
//            request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: [])
//            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        }
//        
//        // 创建 URLSessionDataTask
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            // 检查错误
//            if let _ = error {
//                completion(.failure(.noData))
//                return
//            }
//            
//            // 确保有数据
//            guard let data = data else {
//                completion(.failure(.noData))
//                return
//            }
//            
//            // 尝试解析 JSON 数据
//            do {
//                let decodedObject = try JSONDecoder().decode(T.self, from: data)
//                completion(.success(decodedObject))
//            } catch {
//                completion(.failure(.decodingError))
//            }
//        }
//        
//        // 启动任务
//        task.resume()
//    }
//}
