import 'package:flutter/material.dart';
import '../models/view_mode.dart';
import '../views/user_id_input_view.dart';

class DrawerMenu extends StatelessWidget {
  final ViewMode currentView;
  final ValueChanged<ViewMode> onChange;

  const DrawerMenu({
    super.key,
    required this.currentView,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.calendar_view_week),
            title: const Text('Vue semaine'),
            selected: currentView == ViewMode.week,
            onTap: () => onChange(ViewMode.week),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text('Quitter', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder:
                      (_) => UserIdInputView(
                        controller: TextEditingController(),
                        onSubmit: () {}, // À adapter selon ta logique
                        title: 'Bienvenue',
                      ),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
