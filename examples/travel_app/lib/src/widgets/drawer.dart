import 'package:flutter/material.dart';

class TravelAppDrawer extends StatelessWidget {
  const TravelAppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final currenRoute = ModalRoute.of(context)!.settings;
    final currentPath = currenRoute.name;

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
            selected: currentPath == '/',
            onTap: () {
              final selected = currentPath == '/';
              if (selected) {
                Navigator.pop(context);
                return;
              }
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
          ListTile(
            leading: const Icon(Icons.view_sidebar),
            title: const Text('Side Chat'),
            selected: currentPath == '/side-chat',
            onTap: () {
              final selected = currentPath == '/side-chat';
              if (selected) {
                Navigator.pop(context);
                return;
              }
              Navigator.pushReplacementNamed(context, '/side-chat');
            },
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Canvas Only'),
            selected: currentPath == '/no-chat',
            onTap: () {
              final selected = currentPath == '/no-chat';
              if (selected) {
                Navigator.pop(context);
                return;
              }
              Navigator.pushReplacementNamed(context, '/no-chat');
            },
          ),
        ],
      ),
    );
  }
}
