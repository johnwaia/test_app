import 'package:flutter/material.dart';

class AddPersonalEventView extends StatefulWidget {
  final void Function(
    String title,
    DateTime start,
    DateTime end,
    String? description,
  )
  onEventAdded;

  const AddPersonalEventView({super.key, required this.onEventAdded});

  @override
  State<AddPersonalEventView> createState() => _AddPersonalEventViewState();
}

class _AddPersonalEventViewState extends State<AddPersonalEventView> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _start;
  DateTime? _end;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvel événement personnel')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Titre"),
            ),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: "Description (optionnel)",
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _start == null
                          ? "Début"
                          : "${_start!.day}/${_start!.month} ${_start!.hour}h${_start!.minute.toString().padLeft(2, '0')}",
                    ),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() {
                            _start = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _end == null
                          ? "Fin"
                          : "${_end!.day}/${_end!.month} ${_end!.hour}h${_end!.minute.toString().padLeft(2, '0')}",
                    ),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _start ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() {
                            _end = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Annuler"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_titleController.text.isNotEmpty &&
                          _start != null &&
                          _end != null) {
                        widget.onEventAdded(
                          _titleController.text,
                          _start!,
                          _end!,
                          _descController.text,
                        );
                        Navigator.pop(context);
                      }
                    },
                    child: const Text("Ajouter"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
