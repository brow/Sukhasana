//
//  Results.swift
//  Sukhasana
//
//  Created by Tom Brow on 3/22/15.
//  Copyright (c) 2015 Tom Brow. All rights reserved.
//

import Foundation

struct Results {
  let projects, tasks: [Result]
  
  static var empty: Results {
    return Results(projects: [], tasks: [])
  }
}

struct Result {
  let name, id: String
  var URL: NSURL {
    // FIXME: escape id
    return NSURL(string: "https://app.asana.com/0/\(id)/\(id)")!
  }
}