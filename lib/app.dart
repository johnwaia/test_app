import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'constants/strings.dart';
import 'views/user_id_input_view.dart';
import 'views/home_page.dart';
import 'services/schedule_service.dart';
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

class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

    final path =
        Path()
          ..moveTo(0, 0)
          ..lineTo(size.width / 2, size.height)
          ..lineTo(size.width, 0)
          ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _RootPageState extends State<_RootPage> {
  late final TextEditingController _controller;
  late final tz.Location _noumeaLocation;
  late final ScheduleService _scheduleService;

  bool _showIntro = true;

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
    return Stack(
      children: [
        // Arrière-plan : la page d'accueil classique
        UserIdInputView(
          controller: _controller,
          onSubmit: _handleSubmit,
          title: appTitle,
        ),

        // Premier plan : la bulle d'intro si active
        if (_showIntro)
          GestureDetector(
            onTap: () {
              setState(() {
                _showIntro = false;
              });
            },
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bulle principale
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        "Cette application vous permet de consulter votre emploi du temps universitaire.",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Pointeur style BD
                    CustomPaint(
                      size: const Size(20, 10),
                      painter: TrianglePainter(),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
