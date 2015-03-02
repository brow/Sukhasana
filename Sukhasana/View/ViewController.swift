//
//  ViewController.swift
//  Sukhasana
//
//  Created by Tom Brow on 2/21/15.
//  Copyright (c) 2015 Tom Brow. All rights reserved.
//

import Cocoa

protocol ViewController {
  var view: NSView { get }
  func viewDidDisplay()
}
