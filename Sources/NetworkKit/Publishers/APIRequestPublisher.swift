//
//  APIRequestPublisher.swift
//  
//
//  Created by Richard Blanchard on 6/19/19.
//

import CoreData
import Combine
import Foundation

public struct APIRequestPublisher<Request: APIRequest>: Publisher {
    
    // MARK: - Types
    
    public typealias Output = Result<Request.Output, APIError>
    public typealias Failure = Never
    
    private let request: Request
    private let frequency: PollingFrequency
    private let decoder: JSONDecoder
    private unowned let urlSession: URLSession
    
    init(request: Request,
         frequency: PollingFrequency,
         decoder: JSONDecoder,
         urlSession: URLSession = URLSession.shared
    )
    {
        self.request = request
        self.frequency = frequency
        self.decoder = decoder
        self.urlSession = urlSession
    }
    
    public func receive<S>(subscriber: S) where S : Subscriber, APIRequestPublisher.Failure == S.Failure, APIRequestPublisher.Output == S.Input {
        do {
            let subscription = try APIRequestSubscription<S, Request>(subscriber: subscriber,
                                                                      request: request,
                                                                      frequency: frequency,
                                                                      decoder: decoder,
                                                                      urlSession: urlSession)
            subscriber.receive(subscription: subscription)
            
        } catch {
            _ = subscriber.receive(error.mapToAPIErrorResult())
        }
    }
}


