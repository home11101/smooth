import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/main_navigation_screen.dart';
import 'services/premium_provider.dart';
import 'services/in_app_purchase_service.dart';
import 'services/subscription_service.dart';
import 'services/notification_service.dart';
import 'utils/constants.dart';
import 'utils/app_theme.dart';
import 'screens/onboarding/splash_screen_1.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialisation Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  
  // Configuration du système
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
  // La vérification de la disponibilité des achats est maintenant gérée
  // dans InAppPurchaseService lors de son initialisation.
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<PremiumProvider>(create: (_) => PremiumProvider()),
        Provider<InAppPurchaseService>(create: (_) => InAppPurchaseService()),
        Provider<SubscriptionService>(create: (_) => SubscriptionService()),
        Provider<NotificationService>(create: (_) => NotificationService()),
      ],
      child: SmoothAIApp(),
    ),
  );
}

class SmoothAIApp extends StatefulWidget {
  SmoothAIApp({super.key});

  @override
  State<SmoothAIApp> createState() => _SmoothAIAppState();
}

class _SmoothAIAppState extends State<SmoothAIApp> {
  bool _servicesInitialized = false;

  @override
  Widget build(BuildContext context) {
    if (!_servicesInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeServices(context);
        _servicesInitialized = true;
      });
    }
    return MaterialApp(
      title: 'Smooth AI - Assistant de Rencontres',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const SplashScreen1(),
      routes: {},
    );
  }
  
  void _initializeServices(BuildContext context) {
    final premiumProvider = Provider.of<PremiumProvider>(context, listen: false);
    final inAppPurchaseService = Provider.of<InAppPurchaseService>(context, listen: false);
    final subscriptionService = Provider.of<SubscriptionService>(context, listen: false);
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    
    inAppPurchaseService.initialize(premiumProvider);
    subscriptionService.initialize();
    notificationService.initialize();
  }
}
