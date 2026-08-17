import 'package:flutter/material.dart';

import '../core/app_store.dart';
import '../core/app_theme.dart';
import '../widgets/premium_widgets.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({
    required this.store,
    required this.onUnlocked,
    super.key,
  });

  final AppStore store;
  final VoidCallback onUnlocked;

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final controller = TextEditingController();
  bool loading = false;
  String? error;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> unlock() async {
    setState(() {
      loading = true;
      error = null;
    });
    final valid = await widget.store.verifyPin(controller.text);
    if (!mounted) return;
    if (valid) {
      widget.onUnlocked();
    } else {
      setState(() {
        loading = false;
        error = 'PIN incorreto.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PremiumBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: PremiumCard(
                padding: const EdgeInsets.all(28),
                borderColor: AppColors.green.withValues(alpha: .6),
                child: Column(
                  children: <Widget>[
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: <Color>[AppColors.green, Color(0xFF0AAECA)],
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(Icons.lock_outline, size: 34),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'My Routine Active',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Seus dados ficam somente neste aparelho.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      onSubmitted: (_) => unlock(),
                      decoration: InputDecoration(
                        labelText: 'PIN local',
                        prefixIcon: const Icon(Icons.password),
                        errorText: error,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: loading ? null : unlock,
                        icon: loading
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.login),
                        label: const Text('Entrar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
