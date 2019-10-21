//
//  MockURLSession.swift
//
//

import Combine
import Foundation

public extension URLSession {
    func publisher<Request: APIRequest>(for request: Request, frequency: PollingFrequency = .once, decoder: JSONDecoder, doesBreakpointOnError: Bool) -> APIRequestPublisher<Request> {
        APIRequestPublisher(request: request, frequency: frequency, decoder: decoder, urlSession: self, doesBreakpointOnError: doesBreakpointOnError)
    }
    
    func decodableTypePublisher<T: Decodable>(for urlRequest: URLRequest, decoder: JSONDecoder = JSONDecoder(), doesBreakpointOnError: Bool) -> AnyPublisher<Result<T, APIError>, Never> {
        dataTaskPublisher(for: urlRequest)
            .map { $0.data }
            .decode(type: T.self, decoder: decoder)
            .map { Result.success($0) }
            .catch { return $0.convertToAPIErrorPublisher() }
            .breakpoint(receiveOutput: { (result) -> Bool in
                switch result {
                case .success: return false
                case .failure: return true && doesBreakpointOnError
                }
            })
            .eraseToAnyPublisher()
    }

    func decodableTypePublisher<T: Decodable>(for url: URL, doesBreakpointOnError: Bool) -> AnyPublisher<Result<T, APIError>, Never> {
        decodableTypePublisher(for: URLRequest(url: url), doesBreakpointOnError: doesBreakpointOnError)
    }
}
