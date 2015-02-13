//
//  TableView.swift
//  Sukhasana
//
//  Created by Tom Brow on 2/8/15.
//  Copyright (c) 2015 Tom Brow. All rights reserved.
//

import Cocoa

class TableView: NSTableView {
  override var intrinsicContentSize: NSSize {
    return NSMakeSize(300, CGFloat(numberOfRows) * (rowHeight + intercellSpacing.height))
  }
}