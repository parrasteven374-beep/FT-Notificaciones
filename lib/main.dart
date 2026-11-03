import 'package:material_ui/material_ui.dart';

import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/push_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  await PushService.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Akthlon',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF5A52),
          surface: const Color(0xFFFAF6F1),
        ),
        scaffoldBackgroundColor: const Color(0xFFFAF6F1),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFAF6F1),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
