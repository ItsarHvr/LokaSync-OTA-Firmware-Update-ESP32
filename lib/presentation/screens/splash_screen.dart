import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 2;

  @override
  void initState() {
    super.initState();
  }

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
                          Navigator.pushReplacementNamed(context, '/login');
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