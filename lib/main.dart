import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/main_tab_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mobile_portainer_flutter_module/l10n/app_localizations.dart';
import 'services/notification_service.dart';
import 'services/harmonyos_shared_prefs.dart';
import 'utils/platform_detector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();
  String? languageCode;
  if (PlatformDetector.isOhos) {
    final prefs = await HarmonyosPreferences.getInstance();
    languageCode = await prefs.getString('language_code');
  } else {
    final prefs = await SharedPreferences.getInstance();
    languageCode = prefs.getString('language_code');
  }
  runApp(MyApp(initialLanguageCode: languageCode));
}

class MyApp extends StatefulWidget {
  final String? initialLanguageCode;
  const MyApp({super.key, this.initialLanguageCode});

  static void setLocale(BuildContext context, Locale? newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    if (widget.initialLanguageCode != null) {
      _locale = Locale(widget.initialLanguageCode!);
    }
  }

  void setLocale(Locale? locale) {
    setState(() {
      _locale = locale;
    });
    _saveLocale(locale);
  }

  Future<void> _saveLocale(Locale? locale) async {
    if (PlatformDetector.isOhos) {
      final prefs = await HarmonyosPreferences.getInstance();
      if (locale == null) {
        await prefs.remove('language_code');
      } else {
        await prefs.setString('language_code', locale.languageCode);
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      if (locale == null) {
        await prefs.remove('language_code');
      } else {
        await prefs.setString('language_code', locale.languageCode);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Docker Monitor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('zh'),
      ],
      home: const MainTabScreen(),
    );
  }
}
