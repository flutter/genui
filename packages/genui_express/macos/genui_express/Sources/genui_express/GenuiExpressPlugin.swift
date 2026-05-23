// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Cocoa
import FlutterMacOS
import Foundation
import NaturalLanguage

public class GenuiExpressPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?
  private var activeTask: Task<Void, Never>?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let methodChannel = FlutterMethodChannel(
      name: "genui_express/local_ai",
      binaryMessenger: registrar.messenger
    )
    let eventChannel = FlutterEventChannel(
      name: "genui_express/local_ai_stream",
      binaryMessenger: registrar.messenger
    )

    let instance = GenuiExpressPlugin()
    registrar.addMethodCallDelegate(instance, channel: methodChannel)
    eventChannel.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "checkAvailability":
      if #available(macOS 15.0, iOS 18.0, *) {
        let available = LanguageModelSession.hasCapability(.textGeneration)
        result(available)
      } else {
        result(false)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    self.eventSink = events

    guard let args = arguments as? [String: Any],
      let prompt = args["prompt"] as? String
    else {
      return FlutterError(
        code: "INVALID_ARGUMENTS",
        message: "Missing prompt parameter",
        details: nil
      )
    }

    let systemPrompt = args["systemPrompt"] as? String

    if #available(macOS 15.0, iOS 18.0, *) {
      activeTask = Task {
        do {
          var config = LanguageModelSession.Configuration()
          if let system = systemPrompt {
            config.systemPrompt = system
          }

          let session = try await LanguageModelSession.create(configuration: config)
          let stream = try await session.generateResponse(for: prompt)

          for try await chunk in stream {
            guard !Task.isCancelled else { break }
            events(chunk)
          }

          events(FlutterEndOfEventStream)
        } catch {
          events(
            FlutterError(
              code: "INFERENCE_ERROR",
              message: error.localizedDescription,
              details: nil
            )
          )
        }
      }
    } else {
      events(
        FlutterError(
          code: "UNSUPPORTED_OS",
          message: "FoundationModels requires macOS 15.0 or newer",
          details: nil
        )
      )
    }

    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    activeTask?.cancel()
    activeTask = nil
    eventSink = nil
    return nil
  }
}
