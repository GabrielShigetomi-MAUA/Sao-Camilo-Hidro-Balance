import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/tema_app.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _carregando = false;
  bool _emailEnviado = false;
  String? _erro;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _enviarEmail() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _carregando = false;
          _emailEnviado = true;
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _carregando = false;
        _erro = switch (e.code) {
          'user-not-found' => 'Nenhuma conta encontrada com este e-mail.',
          'invalid-email' => 'Formato de e-mail inválido.',
          _ => 'Ocorreu um erro. Tente novamente.',
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: _emailEnviado ? _telaConfirmacao() : _formulario(),
            ),
          ),
        ),
      ),
    );
  }

  // formulario de envio
  Widget _formulario() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ícone
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.lock_reset,
              color: AppTheme.primaryColor,
              size: 40,
            ),
          ),
        ),

        const SizedBox(height: 24),

        const Center(
          child: Text(
            'Esqueceu a senha?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ),

        const SizedBox(height: 8),

        Center(
          child: Text(
            'Informe seu e-mail e enviaremos um link para redefinir sua senha.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ),

        const SizedBox(height: 36),

        const Text(
          'E-mail',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'seu@email.com',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),

        // erro
        if (_erro != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _erro!,
                    style:
                        TextStyle(color: Colors.red.shade700, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 32),

        ElevatedButton(
          onPressed: _carregando ? null : _enviarEmail,
          child: _carregando
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Enviar link de recuperação'),
        ),

        const SizedBox(height: 16),

        Center(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Voltar ao login',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
        ),
      ],
    );
  }

  // tela de confirmação após envio
  Widget _telaConfirmacao() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),

        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(Icons.mark_email_read_outlined,
              color: Colors.green.shade600, size: 44),
        ),

        const SizedBox(height: 24),

        const Text(
          'E-mail enviado!',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          'Enviamos um link de recuperação para\n${_emailController.text.trim()}',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),

        const SizedBox(height: 8),

        Text(
          'Verifique também a caixa de spam.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey[400]),
        ),

        const SizedBox(height: 40),

        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Voltar ao login'),
        ),
      ],
    );
  }
}