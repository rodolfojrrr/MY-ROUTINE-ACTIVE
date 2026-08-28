import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_store.dart';
import '../core/app_theme.dart';
import '../core/local_account.dart';
import '../widgets/premium_widgets.dart';

class LocalAuthScreen extends StatefulWidget {
  const LocalAuthScreen({
    required this.store,
    required this.onAuthenticated,
    super.key,
  });

  final AppStore store;
  final VoidCallback onAuthenticated;

  @override
  State<LocalAuthScreen> createState() => _LocalAuthScreenState();
}

class _LocalAuthScreenState extends State<LocalAuthScreen> {
  final identifier = TextEditingController();
  final password = TextEditingController();
  final username = TextEditingController();
  final displayName = TextEditingController();
  final email = TextEditingController();
  final newPassword = TextEditingController();
  final confirmPassword = TextEditingController();
  final securityQuestion = TextEditingController();
  final securityAnswer = TextEditingController();
  final legacyPin = TextEditingController();
  bool loading = false;
  bool registerMode = false;
  bool hasAccounts = true;
  bool needsLegacyPin = false;
  bool hidePassword = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final accounts = await widget.store.listAccounts();
    final legacyPinEnabled = accounts.isEmpty && await widget.store.hasPin();
    if (!mounted) return;
    setState(() {
      hasAccounts = accounts.isNotEmpty;
      registerMode = accounts.isEmpty;
      needsLegacyPin = legacyPinEnabled;
    });
  }

  @override
  void dispose() {
    identifier.dispose();
    password.dispose();
    username.dispose();
    displayName.dispose();
    email.dispose();
    newPassword.dispose();
    confirmPassword.dispose();
    securityQuestion.dispose();
    securityAnswer.dispose();
    legacyPin.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (identifier.text.trim().isEmpty || password.text.isEmpty) {
      setState(() => error = 'Informe o usuário/e-mail e a senha.');
      return;
    }
    setState(() {
      loading = true;
      error = '';
    });
    try {
      final account = await widget.store.authenticate(
        identifier.text,
        password.text,
      );
      if (account == null) {
        throw const FormatException('Usuário, e-mail ou senha incorretos.');
      }
      widget.onAuthenticated();
    } catch (exception) {
      if (mounted) setState(() => error = _message(exception));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    if (newPassword.text != confirmPassword.text) {
      setState(() => error = 'As duas senhas não são iguais.');
      return;
    }
    setState(() {
      loading = true;
      error = '';
    });
    try {
      final result = await widget.store.createAccount(
        username: username.text,
        displayName: displayName.text,
        email: email.text,
        password: newPassword.text,
        securityQuestion: securityQuestion.text,
        securityAnswer: securityAnswer.text,
        legacyPin: needsLegacyPin ? legacyPin.text : null,
      );
      if (!mounted) return;
      await _showRecoveryCode(result);
      if (mounted) widget.onAuthenticated();
    } catch (exception) {
      if (mounted) setState(() => error = _message(exception));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _showRecoveryCode(CreatedLocalAccount result) =>
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Guarde seu código de recuperação'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Ele permite criar uma nova senha sem internet. Guarde fora do aplicativo; o código não será mostrado novamente.',
                ),
                const SizedBox(height: 18),
                SelectableText(
                  result.recoveryCode,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: result.recoveryCode));
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(content: Text('Código copiado.')),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copiar código'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Já guardei'),
            ),
          ],
        ),
      );

  Future<void> _recoverPassword() async {
    final recoveryIdentifier = TextEditingController(text: identifier.text);
    final answerOrCode = TextEditingController();
    final first = TextEditingController();
    final second = TextEditingController();
    String? question;
    String dialogError = '';
    var dialogLoading = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Recuperar senha local'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    'A recuperação acontece somente neste aparelho. Use a resposta de segurança ou o código SR guardado.',
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: recoveryIdentifier,
                    decoration: const InputDecoration(
                      labelText: 'Usuário ou e-mail',
                    ),
                    onEditingComplete: () async {
                      final value = await widget.store.recoveryQuestion(
                        recoveryIdentifier.text,
                      );
                      if (context.mounted) {
                        setDialogState(() => question = value);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () async {
                      final value = await widget.store.recoveryQuestion(
                        recoveryIdentifier.text,
                      );
                      if (context.mounted) {
                        setDialogState(() {
                          question = value;
                          dialogError = value == null
                              ? 'Conta local não encontrada.'
                              : '';
                        });
                      }
                    },
                    child: const Text('Mostrar pergunta de segurança'),
                  ),
                  if (question != null) ...<Widget>[
                    const SizedBox(height: 10),
                    Text(
                      question!,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: answerOrCode,
                    decoration: const InputDecoration(
                      labelText: 'Resposta ou código SR',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: first,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Nova senha',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: second,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirmar nova senha',
                    ),
                  ),
                  if (dialogError.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(dialogError,
                        style: const TextStyle(color: AppColors.red)),
                  ],
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: dialogLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: dialogLoading
                  ? null
                  : () async {
                      if (first.text != second.text) {
                        setDialogState(
                          () => dialogError = 'As duas senhas não são iguais.',
                        );
                        return;
                      }
                      setDialogState(() {
                        dialogLoading = true;
                        dialogError = '';
                      });
                      try {
                        final result = await widget.store.resetPassword(
                          identifier: recoveryIdentifier.text,
                          securityAnswerOrRecoveryCode: answerOrCode.text,
                          newPassword: first.text,
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        await _showResetCode(result);
                      } catch (exception) {
                        if (context.mounted) {
                          setDialogState(() {
                            dialogLoading = false;
                            dialogError = _message(exception);
                          });
                        }
                      }
                    },
              child: dialogLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Criar nova senha'),
            ),
          ],
        ),
      ),
    );
    recoveryIdentifier.dispose();
    answerOrCode.dispose();
    first.dispose();
    second.dispose();
  }

  Future<void> _showResetCode(PasswordResetResult result) => showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Senha atualizada'),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'O código anterior foi invalidado. Guarde este novo código:',
                ),
                const SizedBox(height: 16),
                SelectableText(
                  result.newRecoveryCode,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Guardei'),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PremiumBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 820;
                    final hero = _AuthHero(registerMode: registerMode);
                    final form = _form();
                    return wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Expanded(child: hero),
                              const SizedBox(width: 34),
                              SizedBox(width: 470, child: form),
                            ],
                          )
                        : Column(
                            children: <Widget>[
                              hero,
                              const SizedBox(height: 22),
                              form,
                            ],
                          );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _form() {
    return PremiumCard(
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              registerMode ? 'Criar conta local' : 'Entrar no Smart Routine',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 7),
            Text(
              registerMode
                  ? 'Cada conta enxerga somente seus próprios estudos.'
                  : 'Seus dados continuam neste aparelho, sem nuvem.',
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            if (registerMode) ..._registerFields() else ..._loginFields(),
            if (error.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Text(error, style: const TextStyle(color: AppColors.red)),
            ],
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: loading
                  ? null
                  : registerMode
                      ? _register
                      : _login,
              icon: loading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(registerMode ? Icons.person_add_alt_1 : Icons.login),
              label: Text(registerMode ? 'Criar minha conta' : 'Entrar'),
            ),
            if (!registerMode) ...<Widget>[
              TextButton(
                onPressed: loading ? null : _recoverPassword,
                child: const Text('Esqueci minha senha'),
              ),
            ],
            if (hasAccounts || !registerMode) ...<Widget>[
              const Divider(height: 28),
              TextButton(
                onPressed: loading
                    ? null
                    : () => setState(() {
                          registerMode = !registerMode;
                          error = '';
                        }),
                child: Text(
                  registerMode
                      ? 'Já tenho uma conta local'
                      : 'Criar outra conta neste aparelho',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _loginFields() => <Widget>[
        TextField(
          controller: identifier,
          autofillHints: const <String>[
            AutofillHints.username,
            AutofillHints.email
          ],
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Usuário ou e-mail',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: password,
          obscureText: hidePassword,
          autofillHints: const <String>[AutofillHints.password],
          onSubmitted: (_) => _login(),
          decoration: InputDecoration(
            labelText: 'Senha',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              onPressed: () => setState(() => hidePassword = !hidePassword),
              icon:
                  Icon(hidePassword ? Icons.visibility : Icons.visibility_off),
            ),
          ),
        ),
      ];

  List<Widget> _registerFields() => <Widget>[
        TextField(
          controller: displayName,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Nome de exibição'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: username,
          autocorrect: false,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Nome de usuário'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'E-mail (opcional)',
            helperText:
                'Serve apenas como identificador local; nada será enviado.',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: newPassword,
          obscureText: hidePassword,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Senha (mínimo de 6 caracteres)',
            suffixIcon: IconButton(
              onPressed: () => setState(() => hidePassword = !hidePassword),
              icon:
                  Icon(hidePassword ? Icons.visibility : Icons.visibility_off),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: confirmPassword,
          obscureText: hidePassword,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Confirmar senha'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: securityQuestion,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Pergunta de segurança',
            hintText: 'Ex.: nome da minha primeira escola?',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: securityAnswer,
          textInputAction:
              needsLegacyPin ? TextInputAction.next : TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Resposta de segurança',
          ),
        ),
        if (needsLegacyPin) ...<Widget>[
          const SizedBox(height: 12),
          TextField(
            controller: legacyPin,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'PIN usado na versão anterior',
              helperText:
                  'Será solicitado só nesta migração e depois removido.',
            ),
          ),
        ],
      ];

  String _message(Object exception) => exception
      .toString()
      .replaceFirst('FormatException: ', '')
      .replaceFirst('Exception: ', '');
}

class _AuthHero extends StatelessWidget {
  const _AuthHero({required this.registerMode});

  final bool registerMode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[AppColors.primaryLight, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child:
              const Icon(Icons.school_rounded, color: Colors.white, size: 38),
        ),
        const SizedBox(height: 22),
        const Text(
          'Smart Routine SI',
          style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        Text(
          registerMode
              ? 'Organização acadêmica, cursos, código e rotina de estudos em um espaço realmente seu.'
              : 'Entre para continuar exatamente de onde parou no seu ambiente local.',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 17,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 18),
        const Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            _AuthBadge(icon: Icons.cloud_off_outlined, label: 'Sem nuvem'),
            _AuthBadge(icon: Icons.lock_outline, label: 'Contas isoladas'),
            _AuthBadge(icon: Icons.sync, label: 'Wi-Fi local'),
          ],
        ),
      ],
    );
  }
}

class _AuthBadge extends StatelessWidget {
  const _AuthBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(avatar: Icon(icon, size: 17), label: Text(label));
  }
}
