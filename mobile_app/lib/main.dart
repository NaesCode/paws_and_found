import 'package:flutter/material.dart';
import 'core/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/routes/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://pbbrnlytulbaylsbpagx.supabase.co',
    publishableKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBiYnJubHl0dWxiYXlsc2JwYWd4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTAwNjg0NTgsImV4cCI6MjEwNTY0NDQ1OH0.9m6TPNn04dAk12vCAP8aRngOuQ4lw2vySWM8XbHZtHA',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Paws and Found',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
      ),
      routerConfig: AppRouter.router,
    );
  }
}
