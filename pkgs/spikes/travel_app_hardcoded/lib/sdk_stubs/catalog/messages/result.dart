import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart';

import '../../model/controller.dart';
import '../../model/simple_items.dart';
import '../elements/text_intro.dart';
import '../shared/text_styles.dart';

class Result extends StatefulWidget {
  final ResultData data;
  final GenUiController controller;

  const Result(this.data, this.controller, {super.key});

  @override
  State<Result> createState() => _ResultState();
}

class _ResultState extends State<Result> {
  @override
  Widget build(BuildContext context) {
    final uri = Uri.parse(widget.data.imageAssetUrl);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.controller.icon(width: 40, height: 40),
        const SizedBox(height: 18.0),
        Row(
          children: [
            Image.asset(widget.data.imageAssetUrl, height: 100),
            const SizedBox(width: 8.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextIntro(widget.data.textIntroData),
                const SizedBox(height: 8.0),
                Link(
                  uri: uri,
                  builder:
                      (
                        BuildContext context,
                        Future<void> Function()? followLink,
                      ) {
                        return TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.all(0),
                            minimumSize: const Size(0, 0),
                          ),
                          onPressed: () async {
                            // TODO (polina-c): figure out why it does not
                            // open on macOS
                            await followLink!();
                          },
                          child: Text(
                            'View',
                            style: GenUiTextStyles.link(context),
                          ),
                        );
                      },
                ),
                const SizedBox(height: 16.0),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class ResultData extends WidgetData {
  final TextIntroData textIntroData;
  final String imageAssetUrl;
  final String linkUrl;

  ResultData({
    required this.textIntroData,
    required this.imageAssetUrl,
    required this.linkUrl,
  });
}
