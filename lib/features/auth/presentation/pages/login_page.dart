import 'package:elegant_notification/elegant_notification.dart';
import 'package:elegant_notification/resources/arrays.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:lokasync/features/auth/presentation/controllers/auth_controller.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authController = AuthController();
  
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isBiometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
    _checkIfUserIsLoggedIn();
  }

  Future<void> _checkBiometricAvailability() async {
    final isAvailable = await _authController.isBiometricAvailable();
    if (mounted) {
      setState(() {
        _isBiometricAvailable = isAvailable;
      });
    }
  }

  Future<void> _checkIfUserIsLoggedIn() async {
    final isLoggedIn = await _authController.isUserLoggedIn();
    if (isLoggedIn && mounted) {
      // User is already logged in, navigate to home
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Handle login with email and password
  Future<void> _handleEmailPasswordSignIn() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    // debugPrint("DEBUG: Mulai proses login dengan email/password");
    
    try {
      final user = await _authController.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      
      // debugPrint("DEBUG: Login selesai, hasil: ${user != null ? 'sukses' : 'gagal'}");
      
      // Penting: Periksa mounted setelah operasi async
      if (!mounted) {
        // debugPrint("DEBUG: Widget tidak mounted setelah signInWithEmailAndPassword");
        return;
      }
      
      if (user != null) {
        // debugPrint("DEBUG: Login berhasil, menampilkan notifikasi");
        
        // Gunakan WidgetsBinding untuk memastikan notifikasi ditampilkan
        // PERBAIKAN: Hapus parameter autoDismiss: false atau set ke true
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ElegantNotification.success(
            title: const Text("Login Berhasil!"),
            description: Text("Selamat datang kembali ${user.fullName.isNotEmpty ? ', ${user.fullName}' : ''}!"),
            animation: AnimationType.fromTop,
            position: Alignment.topRight,
            // autoDismiss parameter dihapus karena default-nya adalah true
          ).show(context);
        });
        
        // Reset state loading
        setState(() {
          _isLoading = false;
        });
        
        // Navigate to home page
        // debugPrint("DEBUG: Delay sebelum navigasi ke home");
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            // debugPrint("DEBUG: Navigasi ke home page");
            Navigator.pushReplacementNamed(context, '/home');
          }
        });
      } else {
        // debugPrint("DEBUG: User null setelah login");
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ElegantNotification.error(
              title: const Text("Login Gagal"),
              description: const Text("Terjadi kesalahan saat login. Silahkan Coba lagi nanti."),
              animation: AnimationType.fromTop,
              position: Alignment.topRight,
              // autoDismiss parameter dihapus
            ).show(context);
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      // debugPrint("DEBUG: FirebaseAuthException: ${e.code} - ${e.message}");
      
      // Handle specific Firebase Auth exceptions
      String errorMessage = _getFirebaseErrorMessage(e.code);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ElegantNotification.error(
            title: const Text("Login Gagal!"),
            description: Text(errorMessage),
            animation: AnimationType.fromTop,
            position: Alignment.topRight,
            // autoDismiss parameter dihapus
          ).show(context);
        });
      }
    } catch (e) {
      // debugPrint("DEBUG: Exception umum: ${e.toString()}");
      
      // Handle general exceptions
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ElegantNotification.error(
            title: const Text("Error"),
            description: Text("Terjadi kesalahan: ${e.toString()}."),
            animation: AnimationType.fromTop,
            position: Alignment.topRight,
            // autoDismiss parameter dihapus
          ).show(context);
        });
      }
    }
  }

  // Handle login with Google
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });
    
    // debugPrint("DEBUG: Mulai proses login dengan Google");
    
    try {
      // debugPrint("DEBUG: Memanggil signInWithGoogle");
      final user = await _authController.signInWithGoogle();
      
      // debugPrint("DEBUG: Google Sign In selesai, hasil: ${user != null ? 'sukses' : 'gagal'}");
      
      // Pemeriksaan mounted kritis setelah operasi asinkron
      if (!mounted) {
        // debugPrint("DEBUG: Widget tidak mounted setelah signInWithGoogle");
        return;
      }
      
      if (user != null) {
        // debugPrint("DEBUG: Login Google berhasil, menampilkan notifikasi");
        
        // Gunakan WidgetsBinding untuk memastikan notifikasi ditampilkan dengan benar
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ElegantNotification.success(
            title: const Text("Login Berhasil!"),
            description: Text("Berhasil login dengan Google."),
            animation: AnimationType.fromTop,
            position: Alignment.topRight,
          ).show(context);
        });
        
        // Reset loading state sebelum navigasi
        setState(() {
          _isLoading = false;
        });
        
        // Navigasi ke halaman home
        // debugPrint("DEBUG: Delay sebelum navigasi ke home");
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            // debugPrint("DEBUG: Navigasi ke home page");
            Navigator.pushReplacementNamed(context, '/home');
          }
        });
      } else {
        // Handle kasus user null
        // debugPrint("DEBUG: User null setelah Google Sign In");
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ElegantNotification.error(
              title: const Text("Login Gagal"),
              description: const Text("Gagal login dengan Google. Silakan coba lagi."),
              animation: AnimationType.fromTop,
              position: Alignment.topRight,
            ).show(context);
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      // debugPrint("DEBUG: FirebaseAuthException dalam Google Sign In: ${e.code} - ${e.message}");
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ElegantNotification.error(
            title: const Text("Login Gagal!"),
            description: Text(_getFirebaseErrorMessage(e.code)),
            animation: AnimationType.fromTop,
            position: Alignment.topRight,
          ).show(context);
        });
      }
    } catch (e) {
      // debugPrint("DEBUG: Exception umum dalam Google Sign In: ${e.toString()}");
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ElegantNotification.error(
            title: const Text("Error"),
            description: Text("Terjadi kesalahan: ${e.toString()}"),
            animation: AnimationType.fromTop,
            position: Alignment.topRight,
          ).show(context);
        });
      }
    } finally {
      // Pastikan loading dihentikan dalam semua kasus
      // debugPrint("DEBUG: Menjalankan finally block dalam Google Sign In");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Handle login with biometric
  Future<void> _handleBiometricLogin() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = await _authController.signInWithBiometrics();
      
      if (!mounted) return;
      
      if (user != null) {
        // Show success notification
        ElegantNotification.success(
          title: const Text("Login Berhasil!"),
          description: Text("Autentikasi biometrik berhasil"),
          animation: AnimationType.fromTop,
          position: Alignment.topRight,
          autoDismiss: true,
        ).show(context);
        
        // Navigate to home page
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        // Don't show error if user cancelled biometric auth
        if (e.toString().contains('User canceled biometric')) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
        
        ElegantNotification.error(
          title: const Text("Gagal Login dengan Biometrik!"),
          description: Text("Terjadi kesalahan: ${e.toString()}."),
          animation: AnimationType.fromTop,
          position: Alignment.topRight,
          autoDismiss: false,
        ).show(context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper untuk mendapatkan pesan error yang user-friendly
  String _getFirebaseErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'Email tidak terdaftar. Silakan daftar terlebih dahulu.';
      case 'wrong-password':
        return 'Password salah. Silakan coba lagi.';
      case 'invalid-credential':
        return 'Email atau password tidak valid.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan. Hubungi admin.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan login. Coba lagi nanti.';
      case 'email-not-verified':
        return 'Email belum diverifikasi. Cek inbox email Anda.';
      case 'account-exists-with-different-credential':
        return 'Email sudah digunakan dengan metode login lain.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'operation-not-allowed':
        return 'Operasi tidak diizinkan. Hubungi admin.';
      case 'weak-password':
        return 'Password terlalu lemah. Gunakan minimal 8 karakter.';
      case 'network-request-failed':
        return 'Gagal terhubung ke server. Periksa koneksi internet Anda.';
      case 'google-signin-failed':
        return 'Gagal login dengan Google. Silakan coba lagi.';
      default:
        return 'Terjadi kesalahan: $errorCode';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FD), // Background color dari splash screen
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Image.asset(
                    'assets/images/logo_lokasync.png',
                    height: 150,
                  ),
                  const SizedBox(height: 30),
                  
                  // Judul
                  Text(
                    'Login',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF014331), // Hijau tua dari splash screen
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  
                  // Email field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email, color: Color(0xFF014331)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF014331), width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email tidak boleh kosong';
                      }
                      if (!_authController.isValidEmail(value)) {
                        return 'Masukkan email yang valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock, color: Color(0xFF014331)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: const Color(0xFF014331),
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF014331), width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password tidak boleh kosong';
                      }
                      if (value.length < 8) {
                        return 'Password minimal 8 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/forgot-password');
                      },
                      child: Text(
                        'Lupa Password?',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF014331),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Login Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleEmailPasswordSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF014331), // Hijau tua dari splash screen
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      disabledBackgroundColor: Colors.grey.shade400,
                    ),
                    child: _isLoading 
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Masuk',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider(thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'atau',
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(thickness: 1)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Google Sign In Button
                  SignInButton(
                    Buttons.google,
                    onPressed: _isLoading 
                      ? () {} // Fungsi kosong saat loading
                      : _handleGoogleSignIn,
                    text: 'Sign in with Google',
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    // Opsional: Tambahkan opacity saat loading untuk memberi visual feedback
                    // opacity: _isLoading ? 0.6 : 1.0,
                  ),
                  
                  // Show Biometric Button if available
                  if (_isBiometricAvailable) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _handleBiometricLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.fingerprint, color: Colors.white),
                      label: Text(
                        'Login dengan Biometrik',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 20),
                  
                  // Register option
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Belum punya akun?',
                        style: GoogleFonts.poppins(
                          color: Colors.black87,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: Text(
                          'Daftar',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF014331),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}