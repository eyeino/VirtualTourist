//
//  FlickrPost.swift
//  VirtualTourist
//
//  Created by Ian MacFarlane on 8/17/16.
//  Copyright © 2016 Ian MacFarlane. All rights reserved.
//

import Foundation
import Freddy

public struct FlickrPost {
    public let title: String
    public let squareURL: String
}

extension FlickrPost: JSONDecodable {
    public init(json value: JSON) throws {
        title = try value.string(Constants.FlickrResponseKeys.Title)
        squareURL = try value.string(Constants.FlickrResponseKeys.SquareURL)
    }
}