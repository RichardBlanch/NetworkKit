//
//  APIRequestError.swift
//  HackerNews
//
//  Created by Richard Blanchard on 10/8/19.
//  Copyright © 2019 Richard Blanchard. All rights reserved.
//

import Combine
import Foundation

public enum APIError: Error {
    case couldNotCreateRequest
    case decodingError(DecodingError)
    case emptyData
    case generic(Error)
    case invalidStatusCode(HTTPURLResponse)
    case unknown
    case urlError(URLError)
}

// MARK: - Helper

extension APIError {
     static func convert(error: Error) -> APIError {
        guard let apiError = error as? APIError else {
            if let urlError = error as? URLError {
                return .urlError(urlError)
            } else if let decodingError = error as? DecodingError {
                return .decodingError(decodingError)
            }

            return .generic(error)
        }
        
        return apiError
    }
    
    func convertToResultPublisher<T>() -> Just<Result<T, APIError>> {
        return Just(convertToResult())
    }
    
     func convertToResult<T>() -> Result<T, APIError> {
        return Result.failure(self)
    }

     func printError(at url: URL?, file: String = #file, function: String = #function, line: Int = #line) {
        let prefix = "______________________________________\nAPIERROR:\n\nURL: \(url?.absoluteString ?? "UNKNOWN URL")\n\n"
        let postfix = "LOCATION: \(file): \(function) + \(line)\n______________________________________\n\n\n\n"
        print("\(prefix)DESCRIPTION: \(String(describing: errorDescription!))\n\n\(postfix)")
    }
}

// MARK: - CustomNSError

extension APIError: CustomNSError {
    public var errorCode: Int {
        Constant.code
    }
    
    public static var errorDomain: String {
        Constant.domain
    }
}

// MARK: - LocalizedError

extension APIError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .couldNotCreateRequest:
            return "Could Not Create request for URL"
        case .emptyData:
            return "Returned Empty Data while decoding Data"
        case .generic(let error):
            return error.localizedDescription + " with Swift Error Type: \(type(of: error)) - \(error)"
        case .unknown:
            return "UNKNOWN ERROR: POTENTIALLY NIL SELF"
        case .decodingError(let error):
            return "DECODING ERROR: - \(handleDecodingError(error))"
        case .urlError(let error):
            return handleURLError(error)
        case .invalidStatusCode(let httpURLResponse):
            return "INVALID STATUS CODE: \(httpURLResponse.statusCode)"

        }
    }
    
    private func handleURLError(_ urlError: URLError) -> String {
        if let noNetwork = urlError.networkUnavailableReason {
            return "URL ERROR: NO NETWORK! \(noNetwork)"
        } else {
            return "URL ERROR:  \(urlError.localizedDescription) \n"
        }
    }
    
    private func handleDecodingError(_ decodingError: DecodingError) -> String {
        switch decodingError {
        case .dataCorrupted(let context):
            return "DATA CORRUPTED: \(context.debugDescription) - \(context.underlyingError?.localizedDescription ?? "") - CODING PATH: \(context.codingPath)"
        case .keyNotFound(let key, let context):
            let key = "KEY '\(key)' not found:, \(context.debugDescription)"
            let path = "codingPath:, \(context.codingPath)"
            return key + path
        case .valueNotFound(let value, let context):
            return "VALUE: '\(value)' not found - coding Path: \(context.codingPath)"
        case .typeMismatch(let type, let context):
            return "TYPE ISSUE: '\(type)' mismatch: \(context.debugDescription) "
        @unknown default:
            fatalError()
        }
    }

       
    public var failureReason: String? {
        errorDescription // probably want to show this to the user
    }
}

// MARK: - Constant

private extension APIError {
    enum Constant {
        static let domain = "APIError"
        static let code = 710
    }
}

extension Error {
    func mapToAPIError() -> APIError {
        APIError.convert(error: self)
    }
    
    func convertToAPIErrorPublisher<T>() -> Just<Result<T, APIError>> {
        mapToAPIError().convertToResultPublisher()
    }
}
