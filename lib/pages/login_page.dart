import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../providers/auth_provider.dart';
import 'gestor_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => _attemptAutoLogin());
  }

  Future<void> _attemptAutoLogin() async {
    final authProvider = context.read<AuthProvider>();
    try {
      // Si ya había una sesión guardada en el dispositivo, se reusa sin red
      // (evita revocar la sesión activa en otro dispositivo innecesariamente).
      final restored = await authProvider.tryRestoreSession();
      if (!restored) {
        final user = dotenv.env['DEFAULT_LOGIN_USER'] ?? 'admin';
        final password = dotenv.env['DEFAULT_LOGIN_PASSWORD'] ?? 'Admin123!';

        print('🔐 Intentando login con usuario: $user');
        await authProvider.login(user, password);
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const GestorPage()),
        );
      }
    } catch (e) {
      print('Error en login: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Autenticando...'),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Error de Autenticación')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (auth.error != null)
                  Text(
                    auth.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final user = dotenv.env['DEFAULT_LOGIN_USER'] ?? 'admin';
                      final password =
                          dotenv.env['DEFAULT_LOGIN_PASSWORD'] ?? 'Admin123!';
                      await auth.login(user, password);

                      if (mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const GestorPage()),
                        );
                      }
                    } catch (e) {
                      // Error ya está en auth.error
                    }
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
