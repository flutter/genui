// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation

#if canImport(LanguageModeling)
import LanguageModeling
#endif

func runCheck() {
    print("--- Apple Intelligence Capability Check ---")
    
    #if canImport(LanguageModeling)
    if #available(macOS 15.0, iOS 18.0, *) {
        let available = LanguageModelSession.hasCapability(.textGeneration)
        print("OS Support: Yes (macOS 15.0+ & LanguageModeling framework found)")
        print("Text Generation Capability Available: \(available)")
        
        if !available {
            print("\nTip: If it returns false, make sure that:")
            print("1. You are running on an Apple Silicon Mac (M1/M2/M3/M4+).")
            print("2. Apple Intelligence is enabled in 'System Settings > Apple Intelligence & Siri'.")
            print("3. The core English foundation models have finished downloading in the background.")
        }
    } else {
        print("OS Support: No (Requires macOS 15.0 or newer)")
    }
    #else
    print("LanguageModeling framework is not available in your current Swift compilation context.")
    print("Make sure you are building on Xcode 16.0 or newer with macOS 15.0+ SDK.")
    #endif
    print("-------------------------------------------")
}

runCheck()
