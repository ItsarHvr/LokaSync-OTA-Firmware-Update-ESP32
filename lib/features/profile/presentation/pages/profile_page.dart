import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:elegant_notification/resources/arrays.dart';
import 'package:lokasync/features/auth/presentation/controllers/auth_controller.dart';
import 'package:lokasync/features/auth/domain/entities/user_entity.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final _authController = AuthController();
  final _formKey = GlobalKey<FormState>();
  
  // Controllers untuk text fields
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  
  bool _isLoading = false;
  // bool _isPasswordVisible = false;
  FirebaseUserEntity? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  // Load user data
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      final user = _authController.getCurrentUser();
      
      if (user != null) {
        setState(() {
          _currentUser = user;
          _nameController.text = user.fullName;
          _emailController.text = user.email;
        });
      }
    } catch (e) {
      // Error handling
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Handle update profile
  Future<void> _handleUpdateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final updatedUser = await _authController.updateUserProfile(
        displayName: _nameController.text.trim(),
      );
      
      if (!mounted) return;
      
      if (updatedUser != null) {
        setState(() {
          _currentUser = updatedUser;
        });
        
        // Show success notification
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ElegantNotification.success(
            title: const Text("Sukses!"),
            description: const Text("Profil berhasil diperbarui."),
            animation: AnimationType.fromTop,
            position: Alignment.topRight,
          ).show(context);
        });
      }
    } catch (e) {
      if (!mounted) return;
      
      // Show error notification
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ElegantNotification.error(
          title: const Text("Gagal!"),
          description: Text("Gagal memperbarui profil: ${e.toString()}"),
          animation: AnimationType.fromTop,
          position: Alignment.topRight,
        ).show(context);
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Handle change password
  Future<void> _handleChangePassword() async {
    // Show modal bottom sheet for password change
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildChangePasswordSheet(),
    );
  }

  // Handle change email
  Future<void> _handleChangeEmail() async {
    // Show modal bottom sheet for email change
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildChangeEmailSheet(),
    );
  }

  // Handle logout
  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF014331),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    if (result == true) {
      setState(() => _isLoading = true);
      
      try {
        await _authController.signOut();
        
        if (!mounted) return;
        
        // Navigate to login page
        Navigator.pushReplacementNamed(context, '/login');
      } catch (e) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: ${e.toString()}')),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  // Handle delete account
  Future<void> _handleDeleteAccount() async {
    // Show confirmation dialog with password
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDeleteAccountSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF014331)),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
        title: Text(
          'Profile Page',
          style: GoogleFonts.poppins(
            color: const Color(0xFF014331),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading && _currentUser == null
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF014331)))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Card
                    _buildProfileCard(),
                    
                    const SizedBox(height: 24),
                    
                    // Edit Options
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSectionTitle('Edit Profile'),
                          _buildEditNameField(),
                          const SizedBox(height: 16),
                          _buildActionButton(
                            label: 'Update Profile',
                            icon: Icons.save,
                            onPressed: _handleUpdateProfile,
                          ),
                          
                          const SizedBox(height: 32),
                          
                          _buildSectionTitle('Account Settings'),
                          _buildAccountActionTile(
                            title: 'Change Email',
                            icon: Icons.email,
                            onTap: _handleChangeEmail,
                          ),
                          _buildAccountActionTile(
                            title: 'Change Password',
                            icon: Icons.lock,
                            onTap: _handleChangePassword,
                          ),
                          _buildBiometricLoginTile(),
                          
                          const SizedBox(height: 32),
                          
                          _buildSectionTitle('Danger Zone', color: Colors.red),
                          _buildDangerActionTile(
                            title: 'Logout',
                            icon: Icons.logout,
                            onTap: _handleLogout,
                          ),
                          _buildDangerActionTile(
                            title: 'Delete Account Permanently',
                            icon: Icons.delete_forever,
                            onTap: _handleDeleteAccount,
                            isDestructive: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Widget untuk profile card
  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFF014331),
            child: _currentUser?.photoURL != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Image.network(
                      _currentUser!.photoURL!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.white,
                  ),
          ),
          const SizedBox(height: 16),
          
          // User name
          Text(
            _currentUser?.fullName ?? 'User',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF014331),
            ),
          ),
          
          // Email
          Text(
            _currentUser?.email ?? 'email@example.com',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          
          // Verified status
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _currentUser?.isEmailVerified ?? false
                      ? Icons.verified
                      : Icons.error_outline,
                  size: 16,
                  color: _currentUser?.isEmailVerified ?? false
                      ? Colors.green
                      : Colors.orange,
                ),
                const SizedBox(width: 5),
                Text(
                  _currentUser?.isEmailVerified ?? false
                      ? 'Email Verified'
                      : 'Email Not Verified',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: _currentUser?.isEmailVerified ?? false
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk edit nama
  Widget _buildEditNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Full Name',
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
          return 'Name cannot be empty';
        }
        if (value.length < 3) {
          return 'Name must be at least 3 characters';
        }
        return null;
      },
    );
  }

  // Widget untuk action button
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color color = const Color(0xFF014331),
  }) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        disabledBackgroundColor: Colors.grey.shade400,
      ),
      icon: Icon(icon, color: Colors.white),
      label: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
    );
  }

  // Widget untuk section title
  Widget _buildSectionTitle(String title, {Color color = const Color(0xFF014331)}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // Widget untuk account action tile
  Widget _buildAccountActionTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: const Color(0xFF014331)),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            color: const Color(0xFF014331),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  // Widget untuk danger action tile
  Widget _buildDangerActionTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final Color color = isDestructive ? Colors.red.shade700 : Colors.orange.shade700;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDestructive
                ? Colors.red.shade100
                : Colors.orange.shade100,
            blurRadius: 4,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  // Bottom sheet untuk change password
  Widget _buildChangePasswordSheet() {
    final TextEditingController currentPassController = TextEditingController();
    final TextEditingController newPassController = TextEditingController();
    final TextEditingController confirmPassController = TextEditingController();
    bool obscureCurrentPass = true;
    bool obscureNewPass = true;
    bool obscureConfirmPass = true;
    bool isLoading = false;
    
    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Change Password',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF014331),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                
                // Current password
                TextFormField(
                  controller: currentPassController,
                  obscureText: obscureCurrentPass,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: const Icon(Icons.lock, color: Color(0xFF014331)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureCurrentPass ? Icons.visibility : Icons.visibility_off,
                        color: const Color(0xFF014331),
                      ),
                      onPressed: () {
                        setState(() {
                          obscureCurrentPass = !obscureCurrentPass;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // New password
                TextFormField(
                  controller: newPassController,
                  obscureText: obscureNewPass,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.lock_open, color: Color(0xFF014331)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNewPass ? Icons.visibility : Icons.visibility_off,
                        color: const Color(0xFF014331),
                      ),
                      onPressed: () {
                        setState(() {
                          obscureNewPass = !obscureNewPass;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    helperText: 'Min. 8 characters, uppercase, lowercase, number, symbol.',
                  ),
                ),
                const SizedBox(height: 16),
                
                // Confirm new password
                TextFormField(
                  controller: confirmPassController,
                  obscureText: obscureConfirmPass,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF014331)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirmPass ? Icons.visibility : Icons.visibility_off,
                        color: const Color(0xFF014331),
                      ),
                      onPressed: () {
                        setState(() {
                          obscureConfirmPass = !obscureConfirmPass;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Button row
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading 
                            ? null 
                            : () async {
                                // Validate
                                if (currentPassController.text.isEmpty ||
                                    newPassController.text.isEmpty ||
                                    confirmPassController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('All fields are required')),
                                  );
                                  return;
                                }
                                
                                if (newPassController.text != confirmPassController.text) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Passwords do not match')),
                                  );
                                  return;
                                }
                                
                                if (newPassController.text.length < 8) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Password must be at least 8 characters')),
                                  );
                                  return;
                                }

                                // Check password strength
                                final passwordStrength = _authController.checkPasswordStrength(newPassController.text);
                                if (!passwordStrength['isStrong']) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(passwordStrength['message'])),
                                  );
                                  return;
                                }
                                
                                setState(() => isLoading = true);
                                
                                try {
                                  // First re-authenticate
                                  final success = await _authController.reauthenticateUser(
                                    currentPassController.text,
                                  );
                                  
                                  if (!success) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Current password is incorrect')),
                                    );
                                    setState(() => isLoading = false);
                                    return;
                                  }
                                  
                                  // Then update password
                                  await _authController.updatePassword(newPassController.text);
                                  
                                  if (!context.mounted) return;
                                  
                                  // Close sheet
                                  Navigator.pop(context);
                                  
                                  // Show success notification
                                  ElegantNotification.success(
                                    title: const Text("Success!"),
                                    description: const Text("Password has been changed successfully."),
                                    animation: AnimationType.fromTop,
                                    position: Alignment.topRight,
                                  ).show(context);
                                  
                                } catch (e) {
                                  if (!context.mounted) return;
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: ${e.toString()}')),
                                  );
                                } finally {
                                  if (context.mounted) {
                                    setState(() => isLoading = false);
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF014331),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading 
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ) 
                            : Text(
                                'Change Password',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Bottom sheet untuk change email
  Widget _buildChangeEmailSheet() {
    final TextEditingController newEmailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    bool obscurePassword = true;
    bool isLoading = false;
    
    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Change Email',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF014331),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                
                // Current email
                Text(
                  'Current email: ${_currentUser?.email ?? ""}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                
                // New email
                TextFormField(
                  controller: newEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'New Email',
                    prefixIcon: const Icon(Icons.email, color: Color(0xFF014331)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Password
                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: const Icon(Icons.lock, color: Color(0xFF014331)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: const Color(0xFF014331),
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Email verification notice
                Text(
                  'Note: A verification email will be sent to your new email address. You will need to click the verification link before the change takes effect.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Button row
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading 
                            ? null 
                            : () async {
                                // Validate
                                if (newEmailController.text.isEmpty ||
                                    passwordController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('All fields are required')),
                                  );
                                  return;
                                }
                                
                                if (!_authController.isValidEmail(newEmailController.text)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please enter a valid email')),
                                  );
                                  return;
                                }
                                
                                setState(() => isLoading = true);
                                
                                try {
                                  // Re-authenticate user first
                                  final success = await _authController.reauthenticateUser(
                                    passwordController.text,
                                  );
                                  
                                  if (!success) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Current password is incorrect')),
                                    );
                                    setState(() => isLoading = false);
                                    return;
                                  }
                                  
                                  // Update email with password for re-authentication
                                  await _authController.updateEmail(
                                    newEmailController.text,
                                    password: passwordController.text,
                                  );
                                  
                                  // Reload user data
                                  await _loadUserData();
                                  
                                  if (!context.mounted) return;
                                  
                                  // Close sheet
                                  Navigator.pop(context);
                                  
                                  // Show success notification
                                  ElegantNotification.success(
                                    title: const Text("Verification Email Sent"),
                                    description: const Text("Please check your new email and verify it to complete the email change."),
                                    animation: AnimationType.fromTop,
                                    position: Alignment.topRight,
                                  ).show(context);
                                  
                                } catch (e) {
                                  if (!context.mounted) return;
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: ${e.toString()}')),
                                  );
                                } finally {
                                  if (context.mounted) {
                                    setState(() => isLoading = false);
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF014331),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading 
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ) 
                            : Text(
                                'Change Email',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Bottom sheet untuk delete account
  Widget _buildDeleteAccountSheet() {
    final TextEditingController passwordController = TextEditingController();
    bool obscurePassword = true;
    bool isLoading = false;
    
    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red.shade700,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Delete Account',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'This action cannot be undone. All your data will be permanently deleted.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Password for confirmation
                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Enter Password to Confirm',
                    prefixIcon: const Icon(Icons.lock, color: Colors.red),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red.shade700, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Button row
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading 
                            ? null 
                            : () async {
                                if (passwordController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Password is required')),
                                  );
                                  return;
                                }
                                
                                setState(() => isLoading = true);
                                
                                try {
                                  // Re-authenticate user first
                                  final success = await _authController.reauthenticateUser(
                                    passwordController.text,
                                  );
                                  
                                  if (!success) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Password is incorrect')),
                                    );
                                    setState(() => isLoading = false);
                                    return;
                                  }
                                  
                                  // Delete account
                                  await _authController.deleteAccount();
                                  
                                  if (!context.mounted) return;
                                  
                                  // Close sheet
                                  Navigator.pop(context);
                                  
                                  // Navigate to login page
                                  Navigator.pushReplacementNamed(context, '/login');
                                  
                                  // Show notification
                                  ElegantNotification.info(
                                    title: const Text("Account Deleted"),
                                    description: const Text("Your account has been permanently deleted."),
                                    animation: AnimationType.fromTop,
                                    position: Alignment.topRight,
                                  ).show(context);
                                  
                                } catch (e) {
                                  if (!context.mounted) return;
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: ${e.toString()}')),
                                  );
                                } finally {
                                  if (context.mounted) {
                                    setState(() => isLoading = false);
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading 
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ) 
                            : Text(
                                'Delete My Account',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget for biometric login toggle
  Widget _buildBiometricLoginTile() {
    return FutureBuilder<bool>(
      future: _authController.isBiometricAvailable(),
      builder: (context, snapshot) {
        final bool isBiometricAvailable = snapshot.data ?? false;
        
        if (!isBiometricAvailable) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 4,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              leading: const Icon(Icons.fingerprint, color: Colors.grey),
              title: Text(
                'Biometric Login',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              subtitle: Text(
                'Not available on this device',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          );
        }
        
        return FutureBuilder<bool>(
          future: _authController.isBiometricLoginEnabled(),
          builder: (context, enabledSnapshot) {
            final isLoading = !enabledSnapshot.hasData;
            final isEnabled = enabledSnapshot.data ?? false;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 4,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SwitchListTile(
                value: isEnabled,
                onChanged: isLoading 
                    ? null 
                    : (value) async {
                        setState(() => _isLoading = true);
                        
                        try {
                          if (value) {
                            // Show dialog to collect password for enabling biometric login
                            final password = await _showEnableBiometricDialog();
                            
                            if (password != null && password.isNotEmpty && mounted) {
                              // Enable biometric login with the current email and provided password
                              await _authController.enableBiometricLogin(
                                _currentUser!.email,
                                password,
                              );
                              
                              if (!mounted) return;
                              
                              // Show success notification
                              ElegantNotification.success(
                                title: const Text("Success!"),
                                description: const Text("Biometric login has been enabled."),
                                animation: AnimationType.fromTop,
                                position: Alignment.topRight,
                              ).show(context);
                            }
                          } else {
                            // Disable biometric login by clearing stored credentials
                            await _authController.disableBiometricLogin();
                            
                            if (!mounted) return;
                            
                            // Show success notification
                            ElegantNotification.success(
                              title: const Text("Success!"),
                              description: const Text("Biometric login has been disabled."),
                              animation: AnimationType.fromTop,
                              position: Alignment.topRight,
                            ).show(context);
                          }
                          
                          // Force UI refresh
                          if (mounted) {
                            setState(() {});
                          }
                        } catch (e) {
                          if (!mounted) return;
                          
                          // Create a local variable to capture the current BuildContext
                          final currentContext = context;
                          
                          // Show error notification
                          ElegantNotification.error(
                            title: const Text("Error!"),
                            description: Text("Could not update biometric settings: ${e.toString()}"),
                            animation: AnimationType.fromTop,
                            position: Alignment.topRight,
                          ).show(currentContext);
                        } finally {
                          if (mounted) {
                            setState(() => _isLoading = false);
                          }
                        }
                      },
                title: Text(
                  'Biometric Login',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF014331),
                  ),
                ),
                subtitle: Text(
                  isEnabled 
                      ? 'Use fingerprint or face ID to login' 
                      : 'Login with fingerprint or face ID',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                secondary: const Icon(Icons.fingerprint, color: Color(0xFF014331)),
                activeColor: const Color(0xFF014331),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            );
          },
        );
      },
    );
  }
  
  // Dialog to get password for enabling biometric login
  Future<String?> _showEnableBiometricDialog() async {
    final TextEditingController passwordController = TextEditingController();
    bool obscurePassword = true;
    
    return await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              'Enable Biometric Login',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF014331),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enter your password to enable biometric login:',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock, color: Color(0xFF014331)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: const Color(0xFF014331),
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Verify password before enabling biometric
                  final success = await _authController.reauthenticateUser(
                    passwordController.text,
                  );
                  
                  if (!success) {
                    if (!context.mounted) return;
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password is incorrect')),
                    );
                    return;
                  }
                  
                  if (!context.mounted) return;
                  Navigator.pop(context, passwordController.text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF014331),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Enable',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}