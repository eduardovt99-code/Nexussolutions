import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool _isLoading = false;
  String? _message;
  bool _isError = false;

  Future<void> _checkVerification() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });
    
    try {
      HapticFeedback.mediumImpact();
      // Recargar el usuario desde Firebase para refrescar el estado de emailVerified
      await FirebaseAuth.instance.currentUser?.reload();
      
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.emailVerified) {
        // Al recargar, si está verificado, FirebaseAuth enviará un evento al StreamBuilder
        // en main.dart y cambiará la pantalla automáticamente.
        setState(() {
          _message = '¡Verificado exitosamente! Entrando...';
          _isError = false;
        });
      } else {
        setState(() {
          _message = 'El correo aún no ha sido verificado. Por favor, revisa tu bandeja o SPAM.';
          _isError = true;
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error al comprobar verificación. Intenta nuevamente.';
        _isError = true;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendEmail() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });
    
    try {
      HapticFeedback.lightImpact();
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      setState(() {
        _message = '¡Correo reenviado! Revisa tu bandeja de entrada o SPAM.';
        _isError = false;
      });
    } catch (e) {
      setState(() {
        _message = 'Error al reenviar. Es posible que hayas hecho demasiados intentos recientes.';
        _isError = true;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signOut() async {
    HapticFeedback.lightImpact();
    await FirebaseAuth.instance.signOut();
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
                  // Icono gigante
                  Icon(
                    Icons.mark_email_unread_outlined,
                    size: 80,
                    color: AppTheme.brandYellow.withValues(alpha: 0.8),
                  ),
                  const SizedBox(height: 32),
                  
                  const Text(
                    'VERIFICA TU CORREO',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      color: AppTheme.pureWhite,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  const Text(
                    'Para mantener la seguridad de tu cuenta, por favor verifica tu correo electrónico. Haz clic en el enlace que te acabamos de enviar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '(No olvides revisar la carpeta de SPAM o Correo no deseado)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (_message != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: _isError 
                            ? Colors.red.withValues(alpha: 0.1) 
                            : Colors.green.withValues(alpha: 0.1),
                        border: Border.all(
                            color: _isError ? Colors.red : Colors.green),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _message!,
                        style: TextStyle(
                            color: _isError ? Colors.red : Colors.green, 
                            fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Botón principal
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
                      onPressed: _isLoading ? null : _checkVerification,
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
                          : const Text(
                              'YA LO VERIFIQUÉ, ENTRAR',
                              style: TextStyle(
                                letterSpacing: 1.5,
                                color: AppTheme.brandBlack,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Botones secundarios
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _resendEmail,
                    icon: const Icon(Icons.forward_to_inbox, color: Colors.white70),
                    label: const Text('Reenviar correo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Color(0xFF333333)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _isLoading ? null : _signOut,
                    icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                    label: const Text(
                      'Cerrar sesión',
                      style: TextStyle(color: Colors.redAccent),
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
