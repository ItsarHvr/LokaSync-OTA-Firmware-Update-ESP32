import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lokasync/features/auth/presentation/controllers/auth_controller.dart';

class Login extends StatefulWidget {
  final bool showBiometricPrompt;
  
  const Login({
    super.key, 
    this.showBiometricPrompt = false,
  });

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
    
    // Show biometric dialog if requested after a short delay
    if (widget.showBiometricPrompt) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _isBiometricAvailable) {
          _showBiometricDialog();
        }
      });
    }
  }

  Future<void> _checkBiometricAvailability() async {
    final isAvailable = await _authController.isBiometricAvailable();
    final isBiometricLoginEnabled = await _authController.isBiometricLoginEnabled();
    
    if (mounted) {
      setState(() {
        _isBiometricAvailable = isAvailable && isBiometricLoginEnabled;
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

  // Helper function to show customized SnackBar
  void _showSnackBar(String message, bool isSuccess) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Handle login with email and password
  Future<void> _handleEmailPasswordSignIn() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = await _authController.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      
      if (!mounted) return;
      
      if (user != null) {
        // Show success message using SnackBar
        _showSnackBar(
          "Selamat datang kembali${user.fullName.isNotEmpty ? ', ${user.fullName}' : ''}!",
          true
        );
        
        setState(() {
          _isLoading = false;
        });
        
        // Navigate immediately after showing the message
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          _showSnackBar("Terjadi kesalahan saat login. Silahkan Coba lagi nanti.", false);
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = _getFirebaseErrorMessage(e.code);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        _showSnackBar(errorMessage, false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        _showSnackBar("Terjadi kesalahan: ${e.toString()}", false);
      }
    }
  }

  // Show biometric authentication dialog
  Future<void> _showBiometricDialog() async {
    if (!_isBiometricAvailable) {
      if (mounted) {
        _showSnackBar('Biometric login is not available or not enabled', false);
      }
      return;
    }
    
    // Langsung trigger biometric authentication tanpa bottom sheet
    await _triggerBiometricAuth();
  }
  
  // Directly trigger the OS biometric authentication
  Future<void> _triggerBiometricAuth() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      debugPrint('BIOMETRIC_AUTH: Starting biometric authentication flow');
      
      // Show a snackbar to make it clear that we're waiting for fingerprint
      _showSnackBar('Please scan your fingerprint', true);
      
      // First authenticate with biometrics at the OS level
      debugPrint('BIOMETRIC_AUTH: Calling authenticateWithBiometrics()');
      final authenticated = await _authController.authenticateWithBiometrics();
      debugPrint('BIOMETRIC_AUTH: Authentication result: $authenticated');
      
      if (!authenticated) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showSnackBar('Biometric authentication failed or cancelled', false);
        }
        return;
      }
      
      // Skip the second biometric check by accessing stored credentials directly
      debugPrint('BIOMETRIC_AUTH: Authentication successful, attempting to sign in with stored credentials');
      
      try {
        final user = await _authController.signInWithStoredCredentials();
        debugPrint('BIOMETRIC_AUTH: Sign-in result: ${user != null ? 'Success' : 'Failed'}');
        
        if (!mounted) return;
        
        if (user != null) {
          // Show success message
          _showSnackBar("Selamat datang kembali${user.fullName.isNotEmpty ? ', ${user.fullName}' : ''}!", true);
          
          // Navigate immediately
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        }
      } catch (credentialError) {
        debugPrint('BIOMETRIC_AUTH: Credential error: ${credentialError.toString()}');
        
        if (!mounted) return;
        
        // Disable biometric login if credentials are invalid
        if (credentialError.toString().contains('invalid') || 
            credentialError.toString().contains('no longer valid')) {
          
          await _authController.disableBiometricLogin();
          
          _showSnackBar(
            "Your saved credentials are no longer valid. Please login with email and password, then re-enable fingerprint login.",
            false
          );
        } else {
          _showSnackBar("Error: ${credentialError.toString()}", false);
        }
      }
    } catch (e) {
      debugPrint('BIOMETRIC_AUTH: Error: ${e.toString()}');
      if (mounted) {
        // Don't show error if user canceled biometric auth
        if (e.toString().contains('User canceled biometric') || 
            e.toString().contains('user canceled')) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
        
        _showSnackBar("Terjadi kesalahan: ${e.toString()}", false);
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
                    cursorColor: Colors.black,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: Colors.black),
                      prefixIcon: const Icon(Icons.email, color: Color(0xFF014331)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.black, width: 2),
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
                    cursorColor: Colors.black,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: Colors.black),
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
                        borderSide: const BorderSide(color: Colors.black, width: 2),
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
                  
                  if (_isBiometricAvailable) ...[
                    const SizedBox(height: 20),
                    // Biometric login option
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _showBiometricDialog,
                      icon: const Icon(
                        Icons.fingerprint,
                        color: Color(0xFF014331),
                      ),
                      label: Text(
                        'Login dengan Biometrik',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF014331),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFF014331)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
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