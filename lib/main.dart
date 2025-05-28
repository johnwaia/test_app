import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  await initializeDateFormatting('fr_FR', null);
  runApp(const MyApp());
}
