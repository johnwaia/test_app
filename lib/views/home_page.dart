import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/schedule_service.dart'; // si tu as cette classe
import '../models/ics_event.dart'; // si tu utilises IcsEvent

import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class HomePage extends StatefulWidget {
  final String title;
  const HomePage({super.key, required this.title});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final TextEditingController _controller;
  Future<List<IcsEvent>>? _futureEvents;
  late final tz.Location _noumeaLocation;
  late final ScheduleService _scheduleService;

  @override
  void initState() {
    super.initState();
    tzdata.initializeTimeZones(); // Important
    _noumeaLocation = tz.getLocation('Pacific/Noumea');
    _scheduleService = ScheduleService(http.Client());
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(child: Text("Exemple de HomePage")),
    );
  }
}
