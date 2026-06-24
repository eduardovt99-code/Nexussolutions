import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../data/database_service.dart';
import '../models/models.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _companyController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLogin = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccessMessage = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _companyController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final company = _companyController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (_isLogin) {
      if (email.isEmpty || password.isEmpty) {
        setState(() {
          _errorMessage = 'Por favor, llena todos los campos.';
          _isSuccessMessage = false;
        });
        return;
      }
    } else {
      if (email.isEmpty || password.isEmpty || firstName.isEmpty || lastName.isEmpty || company.isEmpty || confirmPassword.isEmpty) {
        setState(() {
          _errorMessage = 'Por favor, llena todos los campos.';
          _isSuccessMessage = false;
        });
        return;
      }
      if (password.length < 4) {
        setState(() {
          _errorMessage = 'La contraseña debe tener al menos 4 caracteres.';
          _isSuccessMessage = false;
        });
        return;
      }
      if (password != confirmPassword) {
        setState(() {
          _errorMessage = 'Las contraseñas no coinciden.';
          _isSuccessMessage = false;
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isSuccessMessage = false;
    });

    HapticFeedback.mediumImpact();

    try {
      // Firebase exige mínimo 6 caracteres. Rellenamos las contraseñas cortas por detrás para engañar a Firebase
      final String safePassword = password.length < 6 ? password + '_TajoAuthPad!' : password;

      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: safePassword,
        );

      } else {
        final userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: safePassword,
        );
        
        final uid = userCred.user?.uid;
        if (uid != null) {
          final profile = UserProfile(
            id: uid,
            firstName: firstName,
            lastName: lastName,
            companyName: company,
            email: email,
            createdAt: DateTime.now(),
          );
          await DatabaseService().saveUserProfile(profile);
          
          // TEMPORAL: Deshabilitado temporalmente el envío de correos de verificación.
          // await userCred.user?.sendEmailVerification();
          
          // Dejamos que el usuario "inicie sesión" normalmente.
          // El StreamBuilder de main.dart ahora lo dejará pasar directamente.
          return;
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isSuccessMessage = false;
        switch (e.code) {
          case 'email-already-in-use':
            _errorMessage = 'Ya existe un usuario registrado con este correo.';
            break;
          case 'invalid-email':
            _errorMessage = 'El correo electrónico no es válido.';
            break;
          case 'weak-password':
            _errorMessage = 'La contraseña es demasiado débil.';
            break;
          case 'user-not-found':
          case 'wrong-password':
          case 'invalid-credential':
            _errorMessage = 'Correo o contraseña incorrectos.';
            break;
          default:
            _errorMessage = e.message ?? 'Ocurrió un error en la autenticación.';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ocurrió un error inesperado.';
        _isSuccessMessage = false;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _moduleChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.brandYellow),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.pureWhite,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.brandBlack,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Center(
                    child: Image.asset(
                      'assets/images/TAJO.png',
                      width: 250,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'EL SISTEMA OPERATIVO DE TU REFORMA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Los tres módulos del pitch
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _moduleChip(Icons.calculate_outlined, 'Presupuesta'),
                      _moduleChip(Icons.groups_2_outlined, 'Dirige el equipo'),
                      _moduleChip(Icons.euro, 'Cobra'),
                    ],
                  ),
                  const SizedBox(height: 48),
                  
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: _isSuccessMessage 
                            ? Colors.green.withValues(alpha: 0.1) 
                            : Colors.red.withValues(alpha: 0.1),
                        border: Border.all(
                            color: _isSuccessMessage ? Colors.green : Colors.red),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                            color: _isSuccessMessage ? Colors.green : Colors.red, 
                            fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  if (!_isLogin) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _firstNameController,
                            style: const TextStyle(color: AppTheme.pureWhite),
                            decoration: InputDecoration(
                              labelText: 'NOMBRE(S)',
                              labelStyle: const TextStyle(color: Colors.white70),
                              prefixIcon: const Icon(Icons.person_outline, color: Colors.white70),
                              filled: true,
                              fillColor: const Color(0xFF1A1A1A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _lastNameController,
                            style: const TextStyle(color: AppTheme.pureWhite),
                            decoration: InputDecoration(
                              labelText: 'APELLIDO(S)',
                              labelStyle: const TextStyle(color: Colors.white70),
                              filled: true,
                              fillColor: const Color(0xFF1A1A1A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _companyController,
                      style: const TextStyle(color: AppTheme.pureWhite),
                      decoration: InputDecoration(
                        labelText: 'NOMBRE DE LA EMPRESA / CONSTRUCTORA',
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.business, color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF1A1A1A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppTheme.pureWhite),
                    decoration: InputDecoration(
                      labelText: 'CORREO ELECTRÓNICO',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF1A1A1A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: AppTheme.pureWhite),
                    decoration: InputDecoration(
                      labelText: 'CONTRASEÑA',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF1A1A1A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _isLogin ? _submit() : null,
                  ),
                  if (!_isLogin) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      style: const TextStyle(color: AppTheme.pureWhite),
                      decoration: InputDecoration(
                        labelText: 'CONFIRMAR CONTRASEÑA',
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF1A1A1A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                  ],
                  const SizedBox(height: 28),
                  // Botón con el gradiente de marca
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppTheme.brandYellow,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.brandYellow.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: AppTheme.brandBlack,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _isLogin ? 'ENTRAR' : 'CREAR CUENTA',
                              style: const TextStyle(
                                letterSpacing: 2,
                                color: AppTheme.brandBlack,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                        _errorMessage = null;
                      });
                    },
                    child: Text(
                      _isLogin
                          ? '¿No tienes cuenta? Regístrate gratis'
                          : '¿Ya tienes cuenta? Inicia sesión',
                      style: const TextStyle(color: AppTheme.brandYellow),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Te devolvemos tus noches. Nos quedamos con tu papeleo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.white54,
                    ),
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
