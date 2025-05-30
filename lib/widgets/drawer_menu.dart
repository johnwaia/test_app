import 'package:flutter/material.dart';
import '../models/view_mode.dart';
import '../views/MeetingOrganizerView.dart';

class DrawerMenu extends StatelessWidget {
  final ViewMode currentView;
  final ValueChanged<ViewMode> onChange;
  final String connectedStudentId;
  final VoidCallback? onAddPersonalEvent;

  const DrawerMenu({
    super.key,
    required this.currentView,
    required this.onChange,
    required this.connectedStudentId,
    this.onAddPersonalEvent,
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
                MaterialPageRoute(
                  builder:
                      (_) => MeetingOrganizerView(
                        connectedStudentId: connectedStudentId,
                      ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.event),
            title: const Text('Créer un événement personnel'),
            onTap: () {
              Navigator.of(context).pop();
              if (onAddPersonalEvent != null) {
                onAddPersonalEvent!();
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text('Quitter', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }
}

// Exemple d'utilisation dans HomePage :
class HomePage extends StatelessWidget {
  final ViewMode _currentView = ViewMode.week;

  void _onViewModeChange(ViewMode viewMode) {
    // Handle view mode change
  }

  void _showAddPersonalEventView(BuildContext context) {
    // Ouvre la vue d'ajout d'événement personnel
    // À implémenter dans la version finale
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon application')),
      drawer: DrawerMenu(
        currentView: _currentView,
        onChange: _onViewModeChange,
        connectedStudentId: '123',
        onAddPersonalEvent: () => _showAddPersonalEventView(context),
      ),
      body: const Center(child: Text('Contenu de la page')),
    );
  }
}
