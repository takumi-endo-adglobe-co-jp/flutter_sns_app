import 'package:flutter/material.dart';
import 'constant/app_colors.dart';
import 'constant/app_strings.dart';
import 'view/home_view.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      home: const HomeView(),
    );
  }
}
