import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../utils/app_theme.dart';
import '../utils/password_validator.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  bool _showPass = false;
  bool _loading = false;
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutQuart));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _phone.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    if (_loading) return;

    setState(() => _loading = true);
    try {
      await _api.login(phoneNumber: _phone.text.trim(), password: _pass.text);
      try {
        await SocketService().connect();
      } catch (e) {
        debugPrint('Socket Error: $e');
      }
      if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      if (mounted) {
        showSnack(context, e.toString(), err: true);
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    // splash screen colors
    const Color splashLime = Color(0xFFFEFD99);
    const Color splashDark = Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: splashLime, // Pure Splash Base Color
      body: Stack(
        children: [
          // Background "Depth" decoration (Subtle gradient overlay)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  splashLime,
                  const Color(0xFFF2F181), // Slightly deeper lime for contrast
                ],
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      SizedBox(height: h * 0.1),

                      // Branding - Consistent with Splash
                      const Text(
                        'InNeed',
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          color: splashDark,
                          letterSpacing: -1.5,
                        ),
                      ),
                      const Text(
                        'LOG IN TO CONTINUE',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: splashDark,
                          letterSpacing: 2,
                        ),
                      ),

                      SizedBox(height: h * 0.08),

                      // Form Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: splashDark,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputLabel('PHONE NUMBER', splashLime),
                              const SizedBox(height: 10),
                              _buildInputField(
                                controller: _phone,
                                hint: '03xx xxxxxxxx',
                                icon: Icons.phone_android_rounded,
                                keyboard: TextInputType.phone,
                                validator: (v) =>
                                    PasswordValidator.isValidPhone(v ?? '')
                                        ? null
                                        : 'Invalid phone format',
                              ),
                              const SizedBox(height: 25),
                              _buildInputLabel('PASSWORD', splashLime),
                              const SizedBox(height: 10),
                              _buildInputField(
                                controller: _pass,
                                hint: '••••••••',
                                icon: Icons.lock_outline_rounded,
                                isPass: true,
                                showPass: _showPass,
                                onToggle: () =>
                                    setState(() => _showPass = !_showPass),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Required'
                                    : null,
                              ),
                              const SizedBox(height: 35),

                              // Main Button
                              SizedBox(
                                width: double.infinity,
                                height: 60,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: splashLime,
                                    foregroundColor: splashDark,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                              color: splashDark,
                                              strokeWidth: 3))
                                      : const Text(
                                          'ACCESS ACCOUNT',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Footer Link
                      TextButton(
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/signup'),
                        child: RichText(
                          text: const TextSpan(
                            text: "Don't have an account? ",
                            style: TextStyle(
                                color: splashDark, fontWeight: FontWeight.w500),
                            children: [
                              TextSpan(
                                text: 'SIGN UP',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  decoration: TextDecoration.underline,
                                ),
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
        ],
      ),
    );
  }

  Widget _buildInputLabel(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        color: color.withOpacity(0.9),
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPass = false,
    bool showPass = false,
    VoidCallback? onToggle,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPass && !showPass,
      keyboardType: keyboard,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFFFEFD99).withOpacity(0.5)),
        suffixIcon: isPass
            ? IconButton(
                icon: Icon(showPass ? Icons.visibility : Icons.visibility_off,
                    color: const Color(0xFFFEFD99).withOpacity(0.5)),
                onPressed: onToggle)
            : null,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFFEFD99), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}
