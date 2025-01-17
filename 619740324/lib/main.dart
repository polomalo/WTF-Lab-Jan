import 'package:flutter/material.dart';

import 'home_page.dart';
import 'light_theme.dart';
import 'theme.dart';

void main() {
  runApp(
    ThemeSwitcherWidget(
      child: MyApp(),
      initialTheme: lightThemeData,
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter project',
      theme: ThemeSwitcher.of(context).themeData,
      home: HomePage(),
    );
  }
}
