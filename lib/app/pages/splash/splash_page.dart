import 'package:flutter/material.dart';

import '../../styles/app_theme.dart';
import '../login/login_page.dart';

/// Pantalla de bienvenida mostrada al abrir la app: logo centrado sobre
/// fondo de marca, sin animaciones de carga ni texto extra, que salta sola
/// al login tras un breve instante — igual al patrón de apps como Foomly.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bosque,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset(
                'assets/images/logo_ratatui.png',
                width: 108,
                height: 108,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Ratatui',
              style: Theme.of(context)
                  .textTheme
                  .displayLarge
                  ?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'RECETAS PARA TU BIENESTAR',
              style: TextStyle(
                color: AppTheme.mostaza,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
