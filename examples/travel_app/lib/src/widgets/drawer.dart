import 'package:flutter/material.dart';

class TravelAppDrawer extends StatelessWidget {
  const TravelAppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.local_airport, size: 48),
                SizedBox(height: 16),
                Text(
                  'Agentic Travel Inc.',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('Inline Chat'),
            selected: _isSelected(context, path: '/'),
            onTap: () => _tapIsSelected(context, path: '/'),
          ),
          ListTile(
            leading: const Icon(Icons.view_sidebar),
            title: const Text('Side Chat'),
            selected: _isSelected(context, path: '/side-chat'),
            onTap: () => _tapIsSelected(context, path: '/side-chat'),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Canvas Only'),
            selected: _isSelected(context, path: '/no-chat'),
            onTap: () => _tapIsSelected(context, path: '/no-chat'),
          ),
        ],
      ),
    );
  }

  void _tapIsSelected(BuildContext context, {required String path}) {
    final isSelected = _isSelected(context, path: path);
    if (isSelected) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, path);
    }
  }

  bool _isSelected(BuildContext context, {required String path}) {
    final currentRoute = ModalRoute.of(context)!.settings;
    final currentPath = currentRoute.name;
    return currentPath == path;
  }
}
