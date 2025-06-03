import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:twitter_clone/common/loading_page.dart';
// import 'package:twitter_clone/common/rounded_small_button.dart'; // Not used in the provided snippet
import 'package:twitter_clone/constants/contants.dart';
import 'package:twitter_clone/features/auth/controller/auth_controller.dart';
import 'package:twitter_clone/features/auth/view/signup_view.dart';
import 'package:twitter_clone/features/auth/widgets/auth_field.dart';
import 'package:twitter_clone/theme/pallete.dart';
import 'package:twitter_clone/theme/theme_controller.dart';

class LoginView extends ConsumerStatefulWidget {
  static route() => MaterialPageRoute(
        builder: (context) => const LoginView(),
      );

  const LoginView({super.key});
  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
  }

  void onLogin() {
    ref.read(authControllerProvider.notifier).login(
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
      // 1. Ensure resizeToAvoidBottomInset is true (default) or remove the line
      // resizeToAvoidBottomInset: true, // Or remove this line entirely
      body: isLoading
          ? const Loader()
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
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
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Centered Twitter logo
                              Center(
                                child: SvgPicture.asset(
                                  AssetsConstants.twitterLogo,
                                  height: 50,
                                  color: Pallete.blueColor,
                                ),
                              ),
                              // Close button positioned at the left
                              Positioned(
                                left: 0,
                                child: IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: Icon(
                                    Icons.close,
                                    color: Theme.of(context).iconTheme.color,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          Text(
                            'Sign in to Twitter',
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 40),
                          // 3. Flattened form fields
                          TwitterAuthField(
                            controller: emailController,
                            hintText: 'Phone, email, or username',
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
                              onPressed: onLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDarkMode ? Colors.white : Colors.black,
                                foregroundColor: isDarkMode ? Colors.black : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Log in',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // 2. Use Spacer instead of fixed SizedBox for flexible spacing
                          const Spacer(), 
                          Padding(
                            padding: const EdgeInsets.fromLTRB(50, 0, 0, 40),
                            child: RichText(
                              text: TextSpan(
                                text: "Don't have an account? ",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Pallete.getSecondaryTextColor(isDarkMode), // Ensure Pallete.getSecondaryTextColor is defined
                                ),
                                children: [
                                  TextSpan(
                                    text: "Sign up",
                                    style: const TextStyle(
                                      color: Pallete.blueColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.push(
                                          context,
                                          SignupView.route(),
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
