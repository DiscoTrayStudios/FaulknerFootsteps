import 'package:faulkner_footsteps/objects/hist_site.dart';
import 'package:faulkner_footsteps/objects/info_text.dart';
import 'package:faulkner_footsteps/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:faulkner_footsteps/pages/list_page.dart';
import 'package:faulkner_footsteps/pages/login_page.dart';
import 'package:faulkner_footsteps/pages/hist_site_page.dart';
import 'package:faulkner_footsteps/pages/start_page.dart';

class AppRouter {
  // shorthand for each page
  static const String startPage = '/';
  static const String loginPage = '/login';
  static const String list = '/list';
  static const String hsitePage = '/hist';
  static const String profilePage = '/profile';

  //static HistSite newSite = HistSite(name: "TEST", blurbs: [InfoText(title: "INTRO", value: "HELLO WORLD")], images: [AssetImage('assets/images/AutobotLogo.png')]);

  // cases for the router, what should happen when moving to this page
  // removed static from infront of Route for HistSitePage
  static Route<dynamic> generateRoute(RouteSettings settings) {
    Map<String, dynamic> info;
    if (settings.arguments != null) {
      info = settings.arguments as Map<String, dynamic>;
    } else {
      info = {
        "info": HistSite(
            name: "Argument Error",
            description: "Please restart the app",
            blurbs: [
              InfoText(
                  title: "there was an error",
                  value:
                      "An error has appeared when trying to navigate to a page for this historical site. Please restart the app.")
            ],
            imageUrls: [],
            lat: 0,
            lng: 0,
            //added ratings here
            avgRating: 0.0,
            ratingAmount: 0,
            filters: [])
      };
    }
    switch (settings.name) {
      case startPage:
        return MaterialPageRoute(builder: (_) => const StartPage());
      case loginPage:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case list:
        return MaterialPageRoute(builder: (_) => ListPage());
      case hsitePage:
        return MaterialPageRoute(
            builder: (_) => HistSitePage(
                histSite: info["info"],
                currentPosition: info["currentPosition"]));
      case profilePage:
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      default:
        return _errorRoute();
    }
  }

  // error catch, displays errors for the user
  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: const Center(
          child: Text('Page not found'),
        ),
      );
    });
  }

  // navigation fo pages, what causes the actual moving between pages
  static Future<void> navigateTo(BuildContext context, String routeName,
      {Map<String, dynamic>? arguments}) async {
    if (routeName == AppRouter.list) {
      await Navigator.pushReplacementNamed(context, list);
    } else {
      await Navigator.pushNamed(context, routeName, arguments: arguments);
    }
  }

  void pop(BuildContext context) {
    Navigator.pop(context);
  }
}
