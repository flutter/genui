// swift-tools-version: 5.9
// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription

let sdkPath: String = {
    let process = Process()
    process.launchPath = "/usr/bin/xcrun"
    process.arguments = ["--sdk", "macosx", "--show-sdk-path"]
    let pipe = Pipe()
    process.standardOutput = pipe
    do {
        try process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !output.isEmpty {
            return output
        }
    } catch {}
    return "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk"
}()

let privateFrameworksPath = "\(sdkPath)/System/Library/PrivateFrameworks"

let package = Package(
    name: "genui_express_macos",
    platforms: [
        .macOS("15.0")
    ],
    products: [
        .library(name: "genui-express-macos", targets: ["genui_express_macos"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "genui_express_macos",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                // If your plugin requires a privacy manifest, for example if it collects user
                // data, update the PrivacyInfo.xcprivacy file to describe your plugin's
                // privacy impact, and then uncomment these lines. For more information, see
                // https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
                // .process("PrivacyInfo.xcprivacy"),

                // If you have other resources that need to be bundled with your plugin, refer to
                // the following instructions to add them:
                // https://developer.apple.com/documentation/xcode/bundling-resources-with-a-swift-package
            ],
            swiftSettings: [
                .unsafeFlags(["-F", privateFrameworksPath]),
                .unsafeFlags(["-F", "/System/Library/PrivateFrameworks"])
            ],
            linkerSettings: [
                .unsafeFlags(["-F", privateFrameworksPath]),
                .unsafeFlags(["-F", "/System/Library/PrivateFrameworks"])
            ]
        )
    ]
)
