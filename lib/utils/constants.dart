import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive/hive.dart';

// Configuration Supabase -  VRAIES VALEURS
const String supabaseUrl = 'https://qlomkoexurbxqsezavdi.supabase.co';
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsb21rb2V4dXJieHFzZXphdmRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEzODYxOTYsImV4cCI6MjA2Njk2MjE5Nn0.eVV4vRp1a_5FVMqqRcSHFC5cjaBEOKCODHZQ76fpED8';

// Configuration OpenAI - Maintenant gérée côté serveur via Supabase Edge Function
const String openAIApiKey = '';
// const String openAIApiKey = 'REMOVED_FOR_SECURITY';

// Configuration Google ML Kit
const String googleMLKitApiKey = 'YOUR_GOOGLE_ML_KIT_API_KEY';

// Configuration Google Vision
const String kGoogleVisionApiKey = 'AIzaSyDgS3kF-tl-ATkD09wtwM9ORnaBUX4tfdk';

final supabase = Supabase.instance.client;

// Stockage local
final userPrefsBox = Hive.box('user_preferences');
final chatHistoryBox = Hive.box('chat_history');
final appDataBox = Hive.box('app_data');

// Navigation
const int chatTabIndex = 0; // Le chat devient l'onglet principal
const int analysisTabIndex = 1; // L'analyse devient le 2ème onglet
const int profileTabIndex = 2;

// Animations
const Duration splashAnimationDuration = Duration(seconds: 4);
const Duration pageTransitionDuration = Duration(milliseconds: 800);
const Duration buttonAnimationDuration = Duration(milliseconds: 300);

// Sons
const String successSoundPath = 'assets/sounds/success.mp3';
const String errorSoundPath = 'assets/sounds/error.mp3';
const String notificationSoundPath = 'assets/sounds/notification.mp3';
const String messageSoundPath = 'assets/sounds/message.mp3';
