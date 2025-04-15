import 'package:elegant_notification/elegant_notification.dart';
import 'package:elegant_notification/resources/arrays.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lokasync/features/auth/presentation/controllers/auth_controller.dart';
import 'package:sign_in_button/sign_in_button.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authController = AuthController();
  
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreeToTerms = false;
  
  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  // Handle registration with email and password
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_agreeToTerms) {
      // debugPrint("DEBUG: Menampilkan notifikasi terms & conditions");
      final notification = ElegantNotification.info(
        title: const Text("Perhatian"),
        description: const Text("Anda harus menyetujui syarat dan ketentuan untuk melanjutkan."),
        animation: AnimationType.fromTop,
        position: Alignment.topRight,
      );
      notification.show(context);
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    // debugPrint("DEBUG: Mulai proses registrasi");
    
    try {
      // Periksa kekuatan password
      final passwordStrength = _authController.checkPasswordStrength(_passwordController.text);
      if (!passwordStrength['isStrong']) {
        // debugPrint("DEBUG: Password lemah, menampilkan notifikasi");
        if (!mounted) return;
        
        final weakPassNotification = ElegantNotification.error(
          title: const Text("Password Lemah!"),
          description: const Text("Gunakan kombinasi huruf besar, kecil, angka, dan simbol."),
          animation: AnimationType.fromTop,
          position: Alignment.topRight,
        );
        
        weakPassNotification.show(context);
        
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // debugPrint("DEBUG: Memanggil registerWithEmailAndPassword");
      final user = await _authController.registerWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _fullNameController.text.trim(),
      );
      
      // debugPrint("DEBUG: Registrasi selesai, hasil: ${user != null ? 'sukses' : 'gagal'}");
      
      // SANGAT PENTING: Periksa mounted setelah operasi async
      if (!mounted) {
        // debugPrint("DEBUG: Widget tidak mounted setelah registerWithEmailAndPassword");
        return;
      }
      
      if (user != null) {
        // debugPrint("DEBUG: User valid, mengirim email verifikasi");
        try {
          // Kirim verifikasi email
          await _authController.sendEmailVerification();
          // debugPrint("DEBUG: Email verifikasi terkirim");
        } catch (verifyError) {
          // debugPrint("DEBUG: Error saat mengirim email verifikasi: $verifyError");
        }
        
        // SANGAT PENTING: Periksa mounted setelah operasi async kedua
        if (!mounted) {
          // debugPrint("DEBUG: Widget tidak mounted setelah sendEmailVerification");
          return;
        }
        
        // debugPrint("DEBUG: Menampilkan notifikasi sukses");

        // PENTING: Tampilkan notifikasi sukses SEBELUM logout
        // PERBAIKAN: Hapus autoDismiss: false
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ElegantNotification.success(
            title: const Text("Registrasi Berhasil!"),
            description: const Text("Silakan cek email Anda untuk verifikasi."),
            animation: AnimationType.fromTop,
            position: Alignment.topRight,
          ).show(context);
        });
        
        // Reset form dan state
        _formKey.currentState!.reset();
        setState(() {
          _agreeToTerms = false;
          // Penting: tetap set loading ke false sebelum navigasi
          _isLoading = false;
        });
        
        // PERBAIKAN: Tambahkan delay yang lebih panjang sebelum signOut 
        // untuk memberikan waktu notifikasi muncul dan dilihat
        await Future.delayed(const Duration(seconds: 2));
        // debugPrint("DEBUG: Melakukan signOut");
        
        // Logout (karena belum verifikasi)
        await _authController.signOut();

        // Pemeriksaan mounted lagi setelah operasi async lainnya
        if (!mounted) return;
        
        // Kembali ke halaman login setelah beberapa detik
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            // debugPrint("DEBUG: Navigasi kembali ke login");
            Navigator.pop(context); // Kembali ke halaman login
          }
        });
      } else {
        // Penting: handle kasus user null (jarang terjadi)
        // debugPrint("DEBUG: User null setelah registrasi");
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          ElegantNotification.error(
            title: const Text("Registrasi Gagal"),
            description: const Text("Terjadi kesalahan saat mendaftar. Silakan coba lagi."),
            animation: AnimationType.fromTop,
            position: Alignment.topRight,
          ).show(context);
        }
      }
    } on FirebaseAuthException catch (e) {
      // debugPrint("DEBUG: FirebaseAuthException: ${e.code} - ${e.message}.");
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ElegantNotification.error(
            title: const Text("Registrasi Gagal!"),
            description: Text(_getFirebaseErrorMessage(e.code)),
            animation: AnimationType.fromTop,
            position: Alignment.topRight,
          ).show(context);
        });
      }
    } catch (e) {
      // debugPrint("DEBUG: Exception umum: ${e.toString()}");
      
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
      // debugPrint("DEBUG: Menjalankan finally block, reset loading");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Handle registration with Google
  Future<void> _handleGoogleSignUp() async {
    if (!_agreeToTerms) {
      // debugPrint("DEBUG: Terms not agreed for Google Sign Up");
      ElegantNotification.info(
        title: const Text("Perhatian"),
        description: const Text("Anda harus menyetujui syarat dan ketentuan untuk melanjutkan."),
        animation: AnimationType.fromTop,
        position: Alignment.topRight,
      ).show(context);
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    // debugPrint("DEBUG: Mulai proses registrasi dengan Google");
    
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
        
        // Gunakan WidgetsBinding untuk memastikan notifikasi ditampilkan
        // PERBAIKAN: Hapus autoDismiss: false
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ElegantNotification.success(
            title: const Text("Registrasi Berhasil!"),
            description: const Text("Akun Google Anda berhasil terdaftar."),
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
        Future.delayed(const Duration(seconds: 2), () {
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
              title: const Text("Registrasi Gagal"),
              description: const Text("Gagal mendaftar dengan Google. Silakan coba lagi."),
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
            title: const Text("Registrasi Gagal!"),
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
  
  // Helper untuk mendapatkan pesan error yang user-friendly
  String _getFirebaseErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'email-already-in-use':
        return 'Email sudah terdaftar. Silakan gunakan email lain atau login.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'operation-not-allowed':
        return 'Registrasi dengan email dan password tidak diizinkan.';
      case 'weak-password':
        return 'Password terlalu lemah. Gunakan minimal 8 karakter.';
      case 'network-request-failed':
        return 'Gagal terhubung ke server. Periksa koneksi internet Anda.';
      case 'account-exists-with-different-credential':
        return 'Email sudah digunakan dengan metode login lain.';
      case 'invalid-credential':
        return 'Kredensial tidak valid. Silakan coba lagi.';
      case 'google-signin-failed':
        return 'Gagal login dengan Google. Silakan coba lagi.';
      default:
        return 'Terjadi kesalahan: $errorCode.';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF014331)),
          onPressed: () => Navigator.pop(context),
        ),
        /* Title AppBar Register
        title: Text(
          'Daftar Akun',
          style: GoogleFonts.poppins(
            color: const Color(0xFF014331),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        */
      ),
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
                    'assets/images/logo_lokasync.png', // Pastikan path ini benar
                    height: 150,
                  ),
                  const SizedBox(height: 20),
                  
                  // Judul
                  Text(
                    'Buat Akun Baru',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF014331),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  
                  // Full Name field
                  TextFormField(
                    controller: _fullNameController,
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Nama Lengkap',
                      prefixIcon: const Icon(Icons.person, color: Color(0xFF014331)),
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
                        return 'Nama tidak boleh kosong';
                      }
                      if (value.length < 3) {
                        return 'Nama minimal 3 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
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
                      helperText: 'Min. 8 karakter, huruf kecil & besar, angka, dan simbol.',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password tidak boleh kosong.';
                      }
                      if (value.length < 8) {
                        return 'Password minimal 8 karakter.';
                      }
                      
                      // Validasi tambahan untuk memastikan password kuat
                      final strength = _authController.checkPasswordStrength(value);
                      if (!strength['hasUppercase']) {
                        return 'Password harus berisi huruf besar.';
                      }
                      if (!strength['hasLowercase']) {
                        return 'Password harus berisi huruf kecil.';
                      }
                      if (!strength['hasSpecialCharacters']) {
                        return 'Password harus berisi simbol.';
                      }
                      if (!strength['hasDigits']) {
                        return 'Password harus berisi minimal satu angka.';
                      }
                      
                      return null;
                    },
                    onChanged: (value) {
                      // Validasi kekuatan password saat diketik
                      if (value.length >= 8) {
                        final strength = _authController.checkPasswordStrength(value);
                        if (!strength['isStrong'] && mounted) {
                          // Tampilkan snackbar dengan pesan spesifik hanya jika password masih lemah
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(strength['message']),
                              backgroundColor: Colors.orange,
                              duration: const Duration(seconds: 3),
                              action: SnackBarAction(
                                label: 'OK',
                                textColor: Colors.white,
                                onPressed: () {
                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                },
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Confirm Password field
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Konfirmasi Password',
                      prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF014331)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: const Color(0xFF014331),
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
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
                        return 'Konfirmasi password tidak boleh kosong.';
                      }
                      if (value != _passwordController.text) {
                        return 'Password tidak cocok.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Terms and Conditions Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _agreeToTerms,
                        onChanged: (value) {
                          setState(() {
                            _agreeToTerms = value ?? false;
                          });
                        },
                        activeColor: const Color(0xFF014331),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _agreeToTerms = !_agreeToTerms;
                            });
                          },
                          child: RichText(
                            text: TextSpan(
                              text: 'Saya menyetujui ',
                              style: GoogleFonts.poppins(
                                color: Colors.black87,
                                fontSize: 12,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Syarat & Ketentuan',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF014331),
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                  // Bisa ditambahkan gesture recognizer untuk membuka terms
                                ),
                                TextSpan(
                                  text: ' dan ',
                                  style: GoogleFonts.poppins(
                                    color: Colors.black87,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Kebijakan Privasi',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF014331),
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                  // Bisa ditambahkan gesture recognizer untuk membuka privacy policy
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  
                  // Register Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF014331),
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
                          'Daftar',
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
                  
                  // Google Sign Up Button
                  SignInButton(
                    Buttons.google,
                    onPressed: _isLoading 
                      ? () {} // Fungsi kosong saat loading
                      : _handleGoogleSignUp,
                    text: 'Daftar dengan Google',
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Login option
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sudah punya akun?',
                        style: GoogleFonts.poppins(
                          color: Colors.black87,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Kembali ke halaman login
                        },
                        child: Text(
                          'Login',
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