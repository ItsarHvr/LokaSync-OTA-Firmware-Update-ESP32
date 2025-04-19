import 'package:elegant_notification/elegant_notification.dart';
import 'package:elegant_notification/resources/arrays.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lokasync/features/auth/presentation/controllers/auth_controller.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authController = AuthController();
  
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Mengirim email reset password
  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    // debugPrint("DEBUG: Memulai proses reset password.");
    
    try {
      await _authController.sendPasswordResetEmail(_emailController.text.trim());
      
      // debugPrint("DEBUG: Email reset password berhasil dikirim.");
      
      // PENTING: Periksa mounted setelah operasi async
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _emailSent = true;
      });
      
      // Tampilkan notifikasi sukses
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ElegantNotification.success(
          title: const Text("Berhasil!"),
          description: const Text("Link reset password telah dikirim ke email Anda."),
          animation: AnimationType.fromTop,
          position: Alignment.topRight,
        ).show(context);
      });
      
      // Reset form, jika berhasil pindah ke login page setelah beberapa detik
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          Navigator.pop(context); // Kembali ke halaman login
        }
      });
      
    } on FirebaseAuthException catch (e) {
      // debugPrint("DEBUG: FirebaseAuthException: ${e.code} - ${e.message}");
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ElegantNotification.error(
            title: const Text("Gagal!"),
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
    }
  }
  
  // Helper untuk mendapatkan pesan error yang user-friendly
  String _getFirebaseErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'Email tidak terdaftar. Pastikan Anda memasukkan email yang benar.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'missing-email':
        return 'Email harus diisi.';
      case 'network-request-failed':
        return 'Gagal terhubung ke server. Periksa koneksi internet Anda.';
      default:
        return 'Terjadi kesalahan: $errorCode.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FD), // Background color sama dengan login dan register
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF014331)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        // Tambahkan bottom padding untuk mencegah overflow dengan notification
        bottom: true,
        minimum: const EdgeInsets.only(bottom: 20),
        child: Center(
          child: SingleChildScrollView(
            // Perbaikan: tambahkan padding bottom lebih besar & buat keyboardDismissBehavior
            padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 40.0),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min, // Gunakan MainAxisSize.min agar column tidak mengambil semua ruang yang tersedia
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
                    'Reset Password',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF014331),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  
                  // Deskripsi
                  Text(
                    'Masukkan email Anda yang terdaftar untuk menerima tautan reset password.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black87,
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
                        return 'Email tidak boleh kosong.';
                      }
                      if (!_authController.isValidEmail(value)) {
                        return 'Masukkan email yang valid.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),
                  
                  // Reset Password Button
                  ElevatedButton(
                    onPressed: _isLoading || _emailSent ? null : _handleResetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF014331),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      disabledBackgroundColor: _emailSent 
                        ? Colors.green.shade400 // Hijau jika email sudah dikirim
                        : Colors.grey.shade400, // Abu-abu jika loading
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
                          _emailSent ? 'Email Terkirim' : 'Kirim Link Reset',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Back to Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Password sudah direset?',
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
                  // Tambahan SizedBox di bagian bawah untuk memberi ruang pada notifikasi
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}