import 'package:flutter/material.dart';
import '../models/view_mode.dart';
import '../views/user_id_input_view.dart';
import '../views/MeetingOrganizerView.dart';

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
            title: const Text('Emploi du temps'),
            selected: currentView == ViewMode.week,
            onTap: () => onChange(ViewMode.week),
          ),
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('Organiser une réunion'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MeetingOrganizerView()),
              );
            },
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
                        onSubmit: () {},
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
