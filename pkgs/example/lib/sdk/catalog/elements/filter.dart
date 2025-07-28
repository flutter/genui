import 'package:flutter/material.dart';

import '../../model/simple_items.dart';

class Filter extends StatefulWidget {
  const Filter(this.data, {super.key});

  final FilterData data;

  @override
  State<Filter> createState() => _FilterState();
}

class _FilterState extends State<Filter> {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,

      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              runSpacing: 8.0,
              spacing: 8.0,
              children: widget.data.items.map(FilterItem.new).toList(),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {},
              child: Text(widget.data.submitLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FilterItem extends StatelessWidget {
  const FilterItem(this.data, {super.key});

  final FilterItemData data;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(data.icon), // The icon to display
      label: Text(data.label), // The text label for the button
      onPressed: () {},
    );
  }
}

class FilterData implements WidgetData {
  final List<FilterItemData> items;
  final String submitLabel;

  FilterData(this.items, {required this.submitLabel});
}

class FilterItemData implements WidgetData {
  final String label;
  final IconData icon;

  FilterItemData({required this.label, required this.icon});
}
