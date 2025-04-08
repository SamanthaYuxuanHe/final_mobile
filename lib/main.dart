/// A mobile application with multiple features including event planning, customer management,
/// expense tracking, and multilingual support.
///
/// This app demonstrates the use of Flutter's internationalization capabilities and
/// provides a modular architecture for various business functions.

import 'package:final_mobile/VehicleMaintenancePage.dart';
import 'package:final_mobile/customer_list_page.dart';
import 'package:final_mobile/event_planner_page.dart';
import 'package:final_mobile/expense_tracker_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Entry point of the application.
///
/// Initializes the Flutter binding, sets up the SQLite database factory,
/// configures localization with support for English and Chinese languages,
/// and runs the app with the initial configuration.
void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite FFI implementation
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Set up localization delegate with supported languages
  var delegate = await LocalizationDelegate.create(
    fallbackLocale: 'en',
    supportedLocales: ['en', 'zh'],
    preferences: TranslatePreferences(),
  );

  // Launch the application with localization support
  runApp(LocalizedApp(delegate, const MyApp()));
}

/// The root widget of the application.
///
/// Sets up the MaterialApp with the appropriate theme, localization,
/// and routes to provide the overall structure for the application.
class MyApp extends StatelessWidget {
  /// Creates a new MyApp instance.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    var localizationDelegate = LocalizedApp.of(context).delegate;
    return LocalizationProvider(
      state: LocalizationProvider.of(context).state,
      child: MaterialApp(
        title: translate('app.title'),
        debugShowCheckedModeBanner: false,
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          localizationDelegate
        ],
        supportedLocales: localizationDelegate.supportedLocales,
        locale: localizationDelegate.currentLocale,
        theme: ThemeData(primarySwatch: Colors.blue),
        home: MyHomePage(),
      ),
    );
  }
}

/// The home page of the application.
///
/// Displays the main menu with buttons to navigate to different features
/// of the app and provides language selection capability.
class MyHomePage extends StatelessWidget {
  /// Creates a new MyHomePage instance.
  const MyHomePage({
    super.key,
  });

  /// Getter for localizations.
  ///
  /// Currently returns null, appears to be a placeholder for future implementation.
  get localizations => null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(translate('home.title')),
        actions: [
          IconButton(
            icon: Icon(Icons.language),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(translate('language.select')),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: Text('English'),
                        onTap: () {
                          changeLocale(context, 'en');
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        title: Text('中文'),
                        onTap: () {
                          changeLocale(context, 'zh');
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomButton(
                  text: translate("button.1"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EventPlannerPage(),
                      ),
                    );
                  }),
              SizedBox(height: 16),
              CustomButton(
                text: translate('customer.list'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CustomerListPage(),
                    ),
                  );
                },
              ),
              SizedBox(height: 16),
              CustomButton(
                  text: translate('expenseTracker'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ExpenseTrackerPage(),
                      ),
                    );
                  }),
              SizedBox(height: 16),
              CustomButton(
                  text: translate('button.4'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VehicleMaintenancePage(),
                      ),
                    );
                  }),
            ],
          ),
        ),
      ),
    );
  }
}

/// A styled button widget used throughout the application.
///
/// Provides consistent styling and appearance for all main navigation
/// buttons in the application.
class CustomButton extends StatelessWidget {
  /// The text to display on the button.
  final String text;

  /// The callback function to execute when the button is pressed.
  final VoidCallback onPressed;

  /// Creates a new CustomButton instance.
  ///
  /// Both [text] and [onPressed] parameters are required.
  const CustomButton({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      child: Text(text),
    );
  }
}

/// Implementation of the ITranslatePreferences interface for localization.
///
/// Manages storing and retrieving the user's preferred language settings.
class TranslatePreferences implements ITranslatePreferences {
  /// Returns the user's preferred locale.
  ///
  /// Currently hardcoded to English locale as default.
  @override
  Future<Locale?> getPreferredLocale() async {
    return const Locale('en');
  }

  /// Saves the user's preferred locale.
  ///
  /// Currently a placeholder method with no implementation.
  @override
  Future savePreferredLocale(Locale locale) async {}
}
