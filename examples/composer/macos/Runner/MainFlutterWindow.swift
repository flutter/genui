// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  override func orderFront(_ sender: Any?) {
    super.orderFront(sender)

    // Set the window size after it's fully initialized.
    // awakeFromNib is too early — Flutter resets the frame.
    let width: CGFloat = 1700
    let height: CGFloat = 1000
    self.setContentSize(NSSize(width: width, height: height))
    self.center()
  }
}
