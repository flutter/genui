// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

const String sampleJsonl = r'''
{"streamHeader": {"version": "1.0.0"}}
{"componentUpdate": {"components": [{"id": "root", "componentProperties": {"Column": {"children": {"explicitList": ["profile_card"]}}}}]}}
{"componentUpdate": {"components": [{"id": "profile_card", "componentProperties": {"Card": {"child": "card_content"}}}]}}
{"componentUpdate": {"components": [{"id": "card_content", "componentProperties": {"Column": {"children": {"explicitList": ["header_row", "bio_text", "stats_row", "interaction_row"]}}}}]}}
{"componentUpdate": {"components": [{"id": "header_row", "componentProperties": {"Row": {"alignment": "center", "children": {"explicitList": ["avatar", "name_column"]}}}}]}}
{"componentUpdate": {"components": [{"id": "avatar", "componentProperties": {"Image": {"url": {"literalString": "https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp&f=y&s=128"}}}}]}}
{"componentUpdate": {"components": [{"id": "name_column", "componentProperties": {"Column": {"alignment": "start", "children": {"explicitList": ["name_text", "handle_text"]}}}}]}}
{"componentUpdate": {"components": [{"id": "name_text", "componentProperties": {"Heading": {"level": "3", "text": {"literalString": "Flutter Fan"}}}}]}}
{"componentUpdate": {"components": [{"id": "handle_text", "componentProperties": {"Text": {"text": {"literalString": "@flutterdev"}}}}]}}
{"componentUpdate": {"components": [{"id": "bio_text", "componentProperties": {"Text": {"text": {"literalString": "Building beautiful, natively compiled applications for mobile, web, and desktop from a single codebase."}}}}]}}
{"componentUpdate": {"components": [{"id": "stats_row", "componentProperties": {"Row": {"distribution": "spaceAround", "children": {"explicitList": ["followers_stat", "following_stat", "likes_stat"]}}}}]}}
{"componentUpdate": {"components": [{"id": "followers_stat", "componentProperties": {"Column": {"children": {"explicitList": ["followers_count", "followers_label"]}}}}]}}
{"componentUpdate": {"components": [{"id": "followers_count", "componentProperties": {"Text": {"text": {"literalString": "1.2M"}}}}]}}
{"componentUpdate": {"components": [{"id": "followers_label", "componentProperties": {"Text": {"text": {"literalString": "Followers"}}}}]}}
{"componentUpdate": {"components": [{"id": "following_stat", "componentProperties": {"Column": {"children": {"explicitList": ["following_count", "following_label"]}}}}]}}
{"componentUpdate": {"components": [{"id": "following_count", "componentProperties": {"Text": {"text": {"literalString": "280"}}}}]}}
{"componentUpdate": {"components": [{"id": "following_label", "componentProperties": {"Text": {"text": {"literalString": "Following"}}}}]}}
{"componentUpdate": {"components": [{"id": "likes_stat", "componentProperties": {"Column": {"children": {"explicitList": ["likes_count", "likes_label"]}}}}]}}
{"componentUpdate": {"components": [{"id": "likes_count", "componentProperties": {"Text": {"text": {"literalString": "10M"}}}}]}}
{"componentUpdate": {"components": [{"id": "likes_label", "componentProperties": {"Text": {"text": {"literalString": "Likes"}}}}]}}
{"componentUpdate": {"components": [{"id": "interaction_row", "componentProperties": {"Row": {"children": {"explicitList": ["follow_button", "message_field"]}}}}]}}
{"componentUpdate": {"components": [{"id": "follow_button", "componentProperties": {"Button": {"label": {"literalString": "Follow"}, "action": {"action": "follow_user"}}}}]}}
{"componentUpdate": {"components": [{"id": "message_field", "componentProperties": {"TextField": {"label": {"literalString": "Send a message..."}}}}]}}
{"dataModelUpdate": {"contents": {}}}
{"beginRendering": {"root": "root"}}
''';
