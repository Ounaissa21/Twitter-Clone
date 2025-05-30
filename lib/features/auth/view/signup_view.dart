import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
// import 'package:twitter_clone/common/common.dart'; // Not used in the provided snippet
import 'package:twitter_clone/common/loading_page.dart';
import 'package:twitter_clone/constants/contants.dart';
import 'package:twitter_clone/features/auth/controller/auth_controller.dart';
import 'package:twitter_clone/features/auth/view/login_view.dart';
import 'package:twitter_clone/features/auth/widgets/auth_field.dart';
import 'package:twitter_clone/theme/pallete.dart'; // Added for Pallete.blueColor and Pallete.getSecondaryTextColor
import 'package:twitter_clone/theme/theme_controller.dart';

class SignupView extends ConsumerStatefulWidget {
  static route() => MaterialPageRoute(
        builder: (context) => const SignupView(),
      );

  const SignupView({super.key});

  @override
  ConsumerState<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends ConsumerState<SignupView> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
  }

  void onSignUP() {
    ref.read(authControllerProvider.notifier).signUp(
        email: emailController.text,
        password: passwordController.text,
        context: context);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider);
    final currentTheme = ref.watch(themeModeProvider);
    final isDarkMode = currentTheme == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // 1. Ensure resizeToAvoidBottomInset is true (default)
      // resizeToAvoidBottomInset: true, // Or remove this line entirely
      body: isLoading
          ? const Loader()
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                // 2. Wrap content with SingleChildScrollView, ConstrainedBox, and IntrinsicHeight
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 40),
                          Center(
                            child: SvgPicture.asset(
                              AssetsConstants.twitterLogo,
                              height: 50,
                              color: Pallete.blueColor, // Ensure Pallete.blueColor is defined
                            ),
                          ),
                          const SizedBox(height: 60),
                          Text(
                            'Create your account',
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 40),
                          // 3. Removed Expanded and inner Column, form fields are direct children
                          TwitterAuthField(
                            controller: emailController,
                            hintText: 'Email',
                          ),
                          const SizedBox(height: 24),
                          TwitterAuthField(
                            controller: passwordController,
                            hintText: 'Password',
                            isPassword: true,
                          ),
                          const SizedBox(height: 40),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: onSignUP,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDarkMode ? Colors.white : Colors.black,
                                foregroundColor: isDarkMode ? Colors.black : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Sign up',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          // 4. Use Spacer to push the login link to the bottom
                          const Spacer(), 
                          Padding(
                            padding: const EdgeInsets.fromLTRB(50, 0, 0, 40),
                            child: RichText(
                              text: TextSpan(
                                text: "Have an account already? ",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Pallete.getSecondaryTextColor(isDarkMode), // Ensure Pallete.getSecondaryTextColor is defined
                                ),
                                children: [
                                  TextSpan(
                                    text: "Log in",
                                    style: const TextStyle(
                                      color: Pallete.blueColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.push(
                                          context,
                                          LoginView.route(),
                                        );
                                      },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}