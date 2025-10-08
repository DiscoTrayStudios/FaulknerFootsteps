// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:faulkner_footsteps/pages/login_page.dart';
import 'package:faulkner_footsteps/pages/start_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:faulkner_footsteps/main.dart';


void main() {
  // test('Blurbs are converted into readable strings', () async {
  //   HistSite testSite =
  //       HistSite(name: "TestName", description: "test description", blurbs: [
  //     InfoText(title: "Test1", value: "A value test", date: "10/6/1995"),
  //     InfoText(title: "Test2", value: "Finding another value")
  //   ], imageUrls: []);
  //   // Build our app and trigger a frame.
  //   String container = testSite.listifyBlurbs();
  //   List<String> blurbStrings = container.split(",");
  //   print(blurbStrings);
  //   List<InfoText> blurbs = [];
  //   for (var blurb in blurbStrings) {
  //     List<String> values = blurb.split(".");
  //     String? Date;
  //     if (values[2] == "null") {
  //       Date = null;
  //     } else {
  //       Date = values[2];
  //     }
  //     blurbs
  //         .add(InfoText(title: values[0], value: values[1], date: "something"));
  //   }
  //   print(blurbs);
  // });

  // testWidgets("Testing firebase pushing and pulling historical sites",
  //     (WidgetTester tester) async {
  //   await tester.pumpWidget(const MyApp());

  //   HistSite testSite =
  //       HistSite(name: "TestName", description: "Test description", blurbs: [
  //     InfoText(title: "Test1", value: "A value test", date: "10/6/1995"),
  //     InfoText(title: "Test2", value: "Finding another value")
  //   ], imageUrls: []);
  //   ApplicationState appState = ApplicationState();
  //   Firebase.initializeApp();
  //   appState.addSite(testSite);
  // });

  // General plan for unit tests:

  // App opens to the Title Screen
  testWidgets("App opens to the Title Screen", (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    final screenFinder = find.byWidget(StartPage());
    expect(screenFinder, findsOneWidget);
  });

  testWidgets("App opens to sign in page", (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    final screenFinder = find.byWidget(LoginPage());
    expect(screenFinder, findsOneWidget);
  });

  testWidgets("App opens to ListView", (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    final screenFinder = find.byWidget(ListView());
    expect(screenFinder, findsOneWidget);
  });

  // Clicking the Title Screen button opens the ListView

  // Clicking the Map button opens the Map Screen

  // Clicking the Achievements button opens the Achievement Screen

  // Clicking on a historical site on the ListView opens the Historical Site Screen
}
