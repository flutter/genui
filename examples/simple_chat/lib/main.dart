// Copyright 2024 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may
// obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ai/firebase_ai.dart' as fb;
import 'package:flutter_genui/flutter_genui.dart' hide ChatMessage;
import 'chat_message.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter and Firebase AI',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessageController> _messages = [];
  final _genUi = GenUiForFirebaseAi(
    firebaseChatSession: _createFirebaseChatSession(),
    // TODO: provide widget catalog and image source
  );
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat with Firebase AI')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return ListTile(
                    title: ChatMessage(message, onSubmitted: _sendUiRequest),
                  );
                },
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'Type your message...',
                      ),
                      onSubmitted: (_) => _sendTextRequest(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendTextRequest,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendTextRequest() async {
    final text = _textController.text;
    if (text.isEmpty) {
      return;
    }

    setState(() {
      _messages.add(ChatMessageController(text: 'You: $text'));
    });

    _textController.clear();
    _scrollToBottom();

    setState(() => _isLoading = true);
    final response = await _genUi.sendTextRequest(text);
    setState(() {
      _messages.add(ChatMessageController(genUiResponse: response));
      _isLoading = false;
    });
    _scrollToBottom();
  }

  Future<void> _sendUiRequest(UserSelection selection) async {
    setState(() => _isLoading = true);
    final response = await _genUi.sendRequestFromGenUi(selection);
    setState(() {
      _messages.add(ChatMessageController(genUiResponse: response));
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

fb.ChatSession _createFirebaseChatSession() {
  final model = fb.FirebaseAI.googleAI().generativeModel(
    model: 'gemini-2.5-flash',
  );
  return model.startChat();
}
