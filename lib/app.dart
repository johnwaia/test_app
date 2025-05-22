import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'constants/strings.dart';
import 'views/user_id_input_view.dart';
import 'views/home_page.dart';
import 'services/schedule_service.dart';
import 'models/ics_event.dart';
import 'package:timezone/timezone.dart' as tz;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      debugShowCheckedModeBanner: false,
      home: _RootPage(),
    );
  }
}

class _RootPage extends StatefulWidget {
  @override
  State<_RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<_RootPage> {
  late final TextEditingController _controller;
  late final tz.Location _noumeaLocation;
  late final ScheduleService _scheduleService;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _noumeaLocation = tz.getLocation(noumeaTimeZone);
    _scheduleService = ScheduleService(http.Client());
  }

  void _handleSubmit() async {
    final userId = _controller.text.trim();
    if (userId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(emptyIdErrorText)));
      return;
    }

    try {
      final events = await _scheduleService.fetchSchedule(
        userId,
        _noumeaLocation,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(title: homePageTitle, events: events),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$errorTextPrefix $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return UserIdInputView(
      controller: _controller,
      onSubmit: _handleSubmit,
      title: appTitle,
    );
  }
}
