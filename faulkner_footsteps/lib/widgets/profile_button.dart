import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:faulkner_footsteps/app_router.dart';

class ProfileButton extends StatelessWidget {
  const ProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(
        Icons.person,
        color: Color.fromARGB(255, 255, 243, 228),
      ),
      onPressed: () {
        print("attempting to get user");
        final user = FirebaseAuth.instance.currentUser;
        if (user == null || user.isAnonymous) {
          print("user is anonymous");
          AppRouter.navigateTo(context, AppRouter.loginPage);
        } else {
          print("user is logged in");
          AppRouter.navigateTo(context, AppRouter.profilePage);
        }
      },
    );
  }
}
