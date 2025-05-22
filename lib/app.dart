import 'package:flutter/material.dart';
import 'views/home_page.dart';

const String homePageTitle = 'Mon Agenda';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: homePageTitle,
      home: const HomePage(title: homePageTitle),
    );
  }
}
