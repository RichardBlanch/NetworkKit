//
//  URLSession+Mocking.swift
//  HackerNews
//
//  Created by Richard Blanchard on 10/18/19.
//  Copyright © 2019 Richard Blanchard. All rights reserved.
//

import Foundation

extension URLSession {
    public static func mockURLSession(mockingWithData data: Data) -> URLSession {
        let config = URLSessionConfiguration.ephemeral

        MockURLProtocol.requestHandler = { request in
            return (HTTPURLResponse(), data)
        }

        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }
}
