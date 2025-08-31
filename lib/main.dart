
import 'package:aroundu/service-providers/job_details.dart';
import 'package:aroundu/service-providers/job_post_form_page.dart';
import 'package:aroundu/service-providers/provider_profile_page.dart';
import 'package:aroundu/service-providers/provider_routing_page.dart';
import 'package:aroundu/workers/worker_profile_page.dart';
import 'package:aroundu/workers/workers_routing_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth/login.dart';
import 'auth/otp_screen.dart';
import 'auth/profile_option.dart';
import 'auth/registration.dart';
import 'constants/OnBoardingPages/on_boarding_page.dart';
import 'constants/loading_screen.dart';
import 'constants/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(
    const AroundU(),
  );
}

class AroundU extends StatelessWidget {
  const AroundU({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/loading': (context) => const LoadingScreen(),
        '/onboarding': (context) => const OnBoardingPage(),
        '/profile-choose': (context) => const ProfileOption(),
        '/splash': (context) => const SplashScreen(),
        '/otp': (context) => const OTPScreen(),
        '/login': (context) => const LoginScreen(),
        '/registration': (context) => const RegistrationPage(),
        '/pprofile': (context) => const ProviderProfilePage(),
        '/wprofile': (context) => const WorkerProfilePage(),
        '/wrouting': (context) => const WorkerRoutingPage(),
        '/prouting': (context) => const ProvidersRoutingPage(),
        '/jobPost': (context) => const JobFormPage(),
        // '/maps': (context) => const Maps(),
        '/jobDetails': (context) => const JobDetailPage(),
        '/wjobdetails': (context) => const JobDetailPage(),
      },
    );
  }
}
