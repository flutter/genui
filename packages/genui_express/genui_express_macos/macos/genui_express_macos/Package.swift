// swift-tools-version: 5.9
// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

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
                .unsafeFlags(["-F", "$(DEVELOPER_SDK_DIR)/MacOSX.sdk/System/Library/PrivateFrameworks"])
            ],
            linkerSettings: [
                .unsafeFlags(["-F", "$(DEVELOPER_SDK_DIR)/MacOSX.sdk/System/Library/PrivateFrameworks"])
            ]
        )
    ]
)
