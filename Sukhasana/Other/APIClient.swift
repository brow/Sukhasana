//
//  Network.swift
//  Sukhasana
//
//  Created by Tom Brow on 2/16/15.
//  Copyright (c) 2015 Tom Brow. All rights reserved.
//

import ReactiveCocoa
import Alamofire

struct APIClient {
  init(APIKey: String) {
    let config = NSURLSessionConfiguration.defaultSessionConfiguration()
    config.HTTPAdditionalHeaders = ["Authorization": "Basic " + ("\(APIKey):" as NSString)
      .dataUsingEncoding(NSUTF8StringEncoding)!
      .base64EncodedStringWithOptions(NSDataBase64EncodingOptions.allZeros)]
    
    requestManager = Manager(configuration: config)
  }
  
  enum TypeaheadType: String {
    case Task = "task"
    case Project = "project"
  }

  func requestTypeaheadResultsInWorkspace(workspaceID: String, ofType type: TypeaheadType, matchingQuery query: String) -> SignalProducer<NSDictionary, NSError> {
    let typeaheadType = "task"
    
    return SignalProducer { observer, _ in
      self.requestManager
        .request(
          .GET,
          // FIXME: escape workspaceID
          "https://app.asana.com/api/1.0/workspaces/\(workspaceID)/typeahead",
          parameters: ["type": type.rawValue, "query": query, "count": 10])
        .validate()
        .responseJSON {_, _, JSON, error in
          if let error = error {
            sendError(observer, error)
          } else {
            if let dict = JSON as? NSDictionary {
              sendNext(observer, dict)
            }
            sendCompleted(observer)
          }
      }
      return
    }
  }
  
  func requestWorkspaces() -> SignalProducer<NSDictionary, NSError> {
    return SignalProducer { observer, _ in
      self.requestManager
        .request(
          .GET,
          "https://app.asana.com/api/1.0/workspaces")
        .validate()
        .responseJSON {_, _, JSON, error in
          if let error = error {
            sendError(observer, error)
          } else {
            if let dict = JSON as? NSDictionary {
              sendNext(observer, dict)
            }
            sendCompleted(observer)
          }
      }
      return
    }
  }
  
  // MARK: private
  private let requestManager: Alamofire.Manager
}
