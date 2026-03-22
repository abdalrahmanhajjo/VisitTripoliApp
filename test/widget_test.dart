import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripoli_explorer/main.dart';
import 'package:tripoli_explorer/providers/app_state.dart';
import 'package:tripoli_explorer/providers/auth_provider.dart';
import 'package:tripoli_explorer/providers/categories_provider.dart';
import 'package:tripoli_explorer/providers/events_provider.dart';
import 'package:tripoli_explorer/providers/interests_provider.dart';
import 'package:tripoli_explorer/providers/language_provider.dart';
import 'package:tripoli_explorer/providers/map_provider.dart';
import 'package:tripoli_explorer/providers/places_provider.dart';
import 'package:tripoli_explorer/providers/profile_provider.dart';
import 'package:tripoli_explorer/providers/tours_provider.dart';
import 'package:tripoli_explorer/providers/trips_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final authProvider = AuthProvider(prefs);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppStateProvider()),
          ChangeNotifierProvider(create: (_) => LanguageProvider(prefs)),
          ChangeNotifierProvider.value(value: authProvider),
          ChangeNotifierProvider(create: (_) => PlacesProvider()),
          ChangeNotifierProvider(
              create: (_) => TripsProvider(prefs, authProvider)),
          ChangeNotifierProvider(create: (_) => MapProvider()),
          ChangeNotifierProvider(create: (_) => CategoriesProvider()),
          ChangeNotifierProvider(create: (_) => ToursProvider()),
          ChangeNotifierProvider(create: (_) => EventsProvider()),
          ChangeNotifierProvider(create: (_) => InterestsProvider()),
          ChangeNotifierProvider(create: (_) => ProfileProvider(prefs)),
        ],
        child: TripoliExplorerApp(authProvider: authProvider),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
