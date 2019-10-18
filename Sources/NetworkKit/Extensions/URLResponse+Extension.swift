//
//  URLResponse+Extension.swift
//  HackerNews
//
//  Created by Richard Blanchard on 10/18/19.
//  Copyright © 2019 Richard Blanchard. All rights reserved.
//

import Foundation

extension URLResponse {
    var httpURLResponse: HTTPURLResponse {
        return self as! HTTPURLResponse
    }
    
    var _statusCode: Int {
        return httpURLResponse.statusCode
    }
    
    var isValidStatus: Bool {
        (200...299).contains(_statusCode)
    }
}
