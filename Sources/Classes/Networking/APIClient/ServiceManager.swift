//
//  ServiceManager.swift
//  MetricsReporter
//
//  Created by Pallab Maiti on 27/06/23.
//

import Foundation

typealias Handler<T> = (HandlerResult<T, NSError>) -> Void

enum HandlerResult<Success, Failure> {
    case success(Success)
    case failure(Failure)
}

enum ErrorCode: Int {
    case UNKNOWN = -1
    case WRONG_WRITE_KEY = 0
    case DECODING_FAILED = 1
    case SERVER_ERROR = 500
}

struct ServiceManager: ServiceType {
//    static let sharedSession: URLSession = {
//        let configuration = URLSessionConfiguration.default
//        configuration.timeoutIntervalForRequest = 30
//        configuration.timeoutIntervalForResource = 30
//        configuration.requestCachePolicy = .useProtocolCachePolicy
//        return URLSession(configuration: configuration)
//    }()
    
    let urlSession: URLSession
    
    init(urlSession: URLSession) {
        self.urlSession = urlSession
    }
    
    func sdkMetrics(params: String, _ completion: @escaping Handler<Bool>) {
        request(.sdkMetrics(params: params), completion)
    }
}

extension ServiceManager {
    func request<T: Codable>(_ API: API, _ completion: @escaping Handler<T>) {
        let urlString = [baseURL(API), path(API)].joined().addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
//        client.log(message: "URL: \(urlString ?? "")", logLevel: .debug)
        var request = URLRequest(url: URL(string: urlString ?? "")!)
        request.httpMethod = method(API).value
        if let headers = headers(API) {
            request.allHTTPHeaderFields = headers
//            client.log(message: "HTTPHeaderFields: \(headers)", logLevel: .debug)
        }
        if let httpBody = httpBody(API) {
            request.httpBody = httpBody
//            client.log(message: "HTTPBody: \(httpBody)", logLevel: .debug)
        }
        let dataTask = urlSession.dataTask(with: request, completionHandler: { (data, response, error) in
            if error != nil {
                completion(.failure(NSError(code: .SERVER_ERROR)))
                return
            }
            let response = response as? HTTPURLResponse
            if let statusCode = response?.statusCode {
                let apiClientStatus = APIClientStatus(statusCode)
                switch apiClientStatus {
                case .success:
                    switch API {
                    case .sdkMetrics:
                        completion(.success(true as! T)) // swiftlint:disable:this force_cast
                    }
                default:
                    let errorCode = handleCustomError(data: data ?? Data())
                    completion(.failure(NSError(code: errorCode)))
                }
            } else {
                completion(.failure(NSError(code: .SERVER_ERROR)))
            }
        })
        dataTask.resume()
    }
    
    func handleCustomError(data: Data) -> ErrorCode {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] else {
                return .SERVER_ERROR
            }
            if let message = json["message"], message == "Invalid write key" {
                return .WRONG_WRITE_KEY
            }
            return .SERVER_ERROR
        } catch {
            return .SERVER_ERROR
        }
    }
}

extension ServiceManager {
    func headers(_ API: API) -> [String: String]? {
        var headers = ["Content-Type": "Application/json",
                       "Content-Encoding": "gzip"]
        switch API {
        case .sdkMetrics:
            headers["Content-Encoding"] = "gzip"
        }
        return headers
    }
    
    func baseURL(_ API: API) -> String {
        switch API {
        case .sdkMetrics:
            return "https://sdkmetrics.rudderstack.com"
        }
    }
    
    func httpBody(_ API: API) -> Data? {
        switch API {
        case .sdkMetrics(let params):
            return params.data(using: .utf8)
        }
    }
    
    func method(_ API: API) -> Method {
        switch API {
        case .sdkMetrics:
            return .post
        }
    }
    
    func path(_ API: API) -> String {
        switch API {
        case .sdkMetrics:
            return "/sdkmetrics"
        }
    }
}

enum Method {
    case post
    case get
    case put
    case delete
    
    var value: String {
        switch self {
        case .post:
            return "POST"
        case .get:
            return "GET"
        case .put:
            return "PUT"
        case .delete:
            return "DELETE"
        }
    }
}

extension NSError {
    convenience init(code: ErrorCode) {
        self.init(domain: "MetricError", code: code.rawValue, userInfo: nil)
    }
}
