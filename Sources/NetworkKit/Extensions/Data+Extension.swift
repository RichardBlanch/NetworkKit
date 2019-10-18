//
//  Data+Extension.swift
//  HackerNews
//
//  Created by Richard Blanchard on 10/17/19.
//  Copyright © 2019 Richard Blanchard. All rights reserved.
//

import Foundation

extension Data {
    var isEmpty: Bool {
        return self == Data()
    }
}
