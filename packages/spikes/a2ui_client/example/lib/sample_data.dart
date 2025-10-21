// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

const String sampleJsonl = r'''
{"surfaceUpdate": {"surfaceId": "1", "components": [{"id": "root", "component": {"Column": {"children": {"explicitList": ["profile_card"]}}}}]}}
{"surfaceUpdate": {"surfaceId": "1", "components": [{"id": "profile_card", "component": {"Card": {"child": "card_content"}}}]}}
{"surfaceUpdate": {"surfaceId": "1", "components": [{"id": "card_content", "component": {"Column": {"children": {"explicitList": ["header_row", "bio_text", "stats_row", "interaction_row"]}}}}]}}
{"surfaceUpdate": {"surfaceId": "1", "components": [{"id": "header_row", "component": {"Row": {"alignment": "center", "children": {"explicitList": ["avatar", "name_column"]}}}}]}}
{"surfaceUpdate": {"surfaceId": "1", "components": [{"id": "avatar", "component": {"Image": {"url": {"literalString": "https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp&f=y&s=128"}}}}]}}
{"surfaceUpdate": {"surfaceId": "1", "components": [{"id": "name_column", "component": {"Column": {"alignment": "start", "children": {"explicitList": ["name_text", "handle_text"]}}}}]}}
{"surfaceUpdate": {"surfaceId": "1", "components": [{"id": "name_text", "component": {"Heading": {"level": "3", "text": {"literalString": "Flutter Fan"}}}}]}}
{"surfaceUpdate": {"surfaceId": "1", "components": [{"id": "handle_text", "component": {"Text": {"text": {"literalString": "@flutterdev"}}}}]}}
{"surfaceUpdate": {"surfaceId": "1", "components": [{"id": "bio_text", "component": {"Text": {"text": {"literalString": "Building beautiful, natively compiled applications for mobile, web, and desktop from a single codebase."}}}}]}}
{"surfaceUpdate": {"surfaceId": "1", "components": [{"id": "stats_row", "component": {"Row": {"distribution": "spaceAround", "children": {"explicitList": ["followers_stat", "following_stat", "likes_stat"]}}}}]}}
{"surfaceUpdate": {"surfaceId": "1", "components": [{"id": "followers_stat", "component": {"Column": {"children": {"explicitList": ["followers_count", "followers_label"]}}}}]}}
{"surfaceUpdate": {"surfaceId": "1", "components": [{"id": "followers_count", "component": {"Text": {"text": {"literalString": "1.2M"}}}}]}}
{"surfaceUpdate": {"surfaceId": "1", "components": [{"id": "followers_label", "component": {"Text": {"text": {"literalString": "Followers"}}}}]}}
{"surfaceUpdate": {"surfaceId": "1", "components": [{"id": "following_stat", "component": {"Column": {"children": {"explicitList": ["following_count", "following_label"]}}}}]}}
{"surfaceUpdate": {"surfaceId": "1", "components": [{"id": "following_count", "component": {"Text": {"text": {"literalString": "280"}}}}]}}
{"surfaceUpdate": {"surfaceId": "1", "components": [{"id": "following_label", "component": {"Text": {"text": {"literalString": "Following"}}}}]}}
{"surfaceUpdate": {"surfaceId": "1", "components": [{"id": "likes_stat", "component": {"Column": {"children": {"explicitList": ["likes_count", "likes_label"]}}}}]}}
{"surfaceUpdate": {"surfaceId": "1", "components": [{"id": "likes_count", "component": {"Text": {"text": {"literalString": "10M"}}}}]}}
{"surfaceUpdate": {"surfaceId": "1", "components": [{"id": "likes_label", "component": {"Text": {"text": {"literalString": "Likes"}}}}]}}
{"surfaceUpdate": {"surfaceId": "1", "components": [{"id": "interaction_row", "component": {"Row": {"children": {"explicitList": ["follow_button", "message_field"]}}}}]}}
{"surfaceUpdate": {"surfaceId": "1", "components": [{"id": "follow_button", "component": {"Button": {"label": {"literalString": "Follow"}, "action": {"name": "follow_user"}}}}]}}
{"surfaceUpdate": {"surfaceId": "1", "components": [{"id": "message_field", "component": {"TextField": {"label": {"literalString": "Send a message..."}}}}]}}
{"dataModelUpdate": {"surfaceId": "1", "contents": {}}}
{"beginRendering": {"surfaceId": "1", "root": "root"}}
''';
