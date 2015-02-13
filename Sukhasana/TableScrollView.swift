//
//  ScrollView.swift
//  Sukhasana
//
//  Created by Tom Brow on 2/12/15.
//  Copyright (c) 2015 Tom Brow. All rights reserved.
//

import Cocoa

class TableScrollView: NSScrollView {
  @IBOutlet var tableView: NSTableView!
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  
  override var intrinsicContentSize: NSSize {
    return tableView.intrinsicContentSize
  }
}
