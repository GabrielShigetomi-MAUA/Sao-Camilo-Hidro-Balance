import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/usuario_service.dart';
import '../../models/usuario.dart';
import '../../theme/tema_app.dart';
import 'widgets/home_atleta.dart';
import 'widgets/home_profissional.dart';

class TelaHome extends StatelessWidget {
  const TelaHome({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<Usuario?>(
      stream: UsuarioService().streamUsuario(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(
              color: AppTheme.primaryColor,
            )),
          );
        }

        final usuario = snapshot.data;
        if (usuario == null) {
          return const Scaffold(
            body: Center(child: Text('Erro ao carregar usuário.')),
          );
        }

        final ehProfissional = ['nutricionista', 'treinador', 'medico']
            .contains(usuario.perfil);

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            title: Row(
              children: [
                const Icon(Icons.water_drop, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'HidroBalance',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_outlined),
                tooltip: 'Sair',
                onPressed: () => _confirmarLogout(context),
              ),
            ],
          ),
          body: ehProfissional
              ? HomeProfissional(usuario: usuario)
              : HomeAtleta(usuario: usuario),
        );
      },
    );
  }

  void _confirmarLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja encerrar sua sessão?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context, '/', (route) => false,
                );
              }
            },
            child: const Text(
              'Sair',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}