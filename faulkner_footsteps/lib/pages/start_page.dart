import 'dart:async';

import 'package:faulkner_footsteps/app_state.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:faulkner_footsteps/app_router.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});
  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    // plays audio when starting the app
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await player.setSourceAsset('audio/GuitarStrumFF.mp3');
      await player.resume();

      Future.delayed(Duration(seconds: 2), () {
        fadeOutAudio();
      });
    });
  }

  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = Provider.of<ApplicationState>(context, listen: false);
    print("✅ appState loaded in startpage: ${appState.historicalSites.length}");
  }

  // Handles the fade out of the Guitar strum
  void fadeOutAudio() {
    const steps = 20;
    const stepDuration = Duration(milliseconds: 100);
    double volume = 1.0;

    Timer.periodic(stepDuration, (timer) {
      volume -= 1 / steps;
      if (volume <= 0) {
        player.stop();
        timer.cancel();
      } else {
        player.setVolume(volume);
      }
    });
  }

  void _handleContinue() async {
    player.stop(); // Stop the audio

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print("already signed in");
    } else {
      print("signing in anonymously");
      try {
        UserCredential credential =
            await FirebaseAuth.instance.signInAnonymously();
        user = credential.user;
        print("signed in as ${user?.uid}");
      } catch (e) {
        print("Anonymous sign-in failed: $e");
        return; // Don't navigate if sign-in fails
      }
    }

    AppRouter.navigateTo(context, AppRouter.list);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
        opacity: _animation,
        child: AnimatedContainer(
            duration: Duration(seconds: 5),
            decoration: BoxDecoration(
                gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 12,
                    colors: [
                  Color.fromARGB(255, 72, 52, 52),
                  Color.fromARGB(255, 184, 141, 106),
                ])),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(175.0),
                      child: Image.asset(
                        'assets/images/FFSplash2.png',
                        width: 400, // Adjust the size as needed
                        height: 400,
                      ),
                    ),
                    const SizedBox(height: 50),
                    Container(
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 255, 243, 228),
                        border: Border.all(
                          color: const Color.fromARGB(255, 176, 133, 133),
                          width: 3.0,
                        ),
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8.0,
                            offset: Offset(3, 4), // Shadow offset
                          ),
                        ],
                      ),
                      width: 350, // Rectangular width
                      height: 120, // Rectangular height
                      child: InkWell(
                        onTap: _handleContinue,
                        borderRadius: BorderRadius.circular(12.0),
                        child: Center(
                          child: Text(
                            'Get To Steppin',
                            style: GoogleFonts.ultra(
                              textStyle: const TextStyle(
                                color: Color.fromARGB(255, 107, 79, 79),
                                fontSize: 24,
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
