import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lokasync/features/auth/presentation/controllers/auth_controller.dart';
import 'package:lokasync/presentation/controllers/auth_controller.dart' as auth_wrapper;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends State<SplashScreen> {
  // Key for checking if it's the first time running the app
  static const String _keyIsFirstRun = 'is_first_run';
  bool _isFirstRun = true;
  final _authController = AuthController();

  @override
  void initState() {
    super.initState();
    // Start preloading resources immediately in background
    _preloadResourcesInBackground();
  }

  Future<void> _preloadResourcesInBackground() async {
    try {
      // debugPrint('SPLASH: Starting background preloading');
      
      // Load preferences and auth state in parallel using Future.wait
      final results = await Future.wait([
        SharedPreferences.getInstance(),
        _authController.isUserLoggedIn(),
        _authController.isBiometricAvailable(),
        // Pre-cache authentication state
        FirebaseAuth.instance.authStateChanges().first,
      ]);
      
      final prefs = results[0] as SharedPreferences;
      _isFirstRun = prefs.getBool(_keyIsFirstRun) ?? true;
      
      // If first run, mark it as run
      if (_isFirstRun) {
        await prefs.setBool(_keyIsFirstRun, false);
      }
      
      // Minimum delay to avoid visual flicker
      await Future.delayed(const Duration(milliseconds: 500));
      
      // debugPrint('SPLASH: Background preloading complete');
    } catch (e) {
      // debugPrint('SPLASH: Error during preloading: $e');
    } finally {
      if (mounted) {
        _navigateToNextScreen();
      }
    }
  }
  
  void _navigateToNextScreen() {
    if (_isFirstRun) {
      // First time running the app - show the onboarding screen
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    } else {
      // Not first time - go directly to authentication wrapper
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const auth_wrapper.AuthenticationWrapper()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FD),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Image.asset(
              'assets/images/logo_lokasync.png',
              height: 200,
            ),
            const SizedBox(height: 30),
            
            // Loading indicator
            const CircularProgressIndicator(
              color: Color(0xFF014331),
            ),
          ],
        ),
      ),
    );
  }
}

// Onboarding screen (previously separate Splash class)
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 2;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Background warna putih agak gelap sesuai permintaan
        color: const Color.fromARGB(255, 222, 242, 217),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  children: [
                    // First Slide
                    _buildSlide(
                      image: 'assets/images/bg_splash1.png',
                      description: 'Instalasi gak ribet, cukup pasang dan jalankan.',
                    ),
                    
                    // Second Slide
                    _buildSlide(
                      image: 'assets/images/bg_splash2.png',
                      description: 'Monitoring versi firmware ESP secara real-time.',
                    ),
                  ],
                ),
              ),
              
              // Button (only shown on last page)
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: _currentPage == _totalPages - 1
                    ? ElevatedButton(
                        onPressed: () {
                          // Go directly to AuthWrapper instead of login
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const auth_wrapper.AuthenticationWrapper(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF014331), // Warna hijau tua
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          'Get Started',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // Teks putih
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeIn,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF014331), // Warna hijau tua
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          'Next',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // Teks putih
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlide({required String image, required String description}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Image.asset(
            image,
            height: 300,
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
          // Indicator dots di bawah description
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _buildPageIndicator(),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageIndicator() {
    List<Widget> indicators = [];
    for (int i = 0; i < _totalPages; i++) {
      // Mengubah bentuk indikator berdasarkan current page
      indicators.add(
        Container(
          // Jika halaman saat ini, buat oval/lonjong, jika tidak buat bulat
          width: _currentPage == i ? 25 : 10,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            // Jika bukan current page, gunakan bentuk bulat (circle)
            borderRadius: BorderRadius.circular(4),
            color: _currentPage == i ? const Color(0xFF014331) : Colors.grey.shade400, // Warna indicator sama dengan button
          ),
        ),
      );
    }
    return indicators;
  }
}