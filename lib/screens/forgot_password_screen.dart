import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../enums/view_state.dart';
import '../view_models/forgot_password_view_model.dart';
import '../models/background_shape.dart';

import '../widgets/artistic_background.dart';
import '../providers/theme_notifier.dart';
import '../theme/custom_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ForgotPasswordViewModel>().resetState();
    });

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    await context.read<ForgotPasswordViewModel>().sendResetEmail(
      email: _emailController.text.trim(),
      onSuccess: () {
        if (!mounted) return;
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) Navigator.of(context).pop();
        });
      },
      onError: (message) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ForgotPasswordViewModel>();
    final theme = Theme.of(context);
    final themeNotifier = context.watch<ThemeNotifier>();
    final isDark = theme.brightness == Brightness.dark;
    Color appBarColor = isDark ? theme.colorScheme.surface : theme.colorScheme.primary;
    Color onAppBarColor = isDark ? theme.colorScheme.onSurface : theme.colorScheme.onPrimary;

    final accent = theme.colorScheme.tertiary;
    final primary = theme.colorScheme.primary;
    final List<BackgroundShape> forgotPasswordPattern = [
      BackgroundShape(
        top: -50,
        right: -120,
        width: 250,
        height: 250,
        color: accent.withAlpha(isDark ? 40 : 60),
      ),
      BackgroundShape(
        bottom: -100,
        left: -100,
        width: 300,
        height: 300,
        color: primary.withAlpha(isDark ? 40 : 60),
      ),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Lupa Password', style: theme.textTheme.headlineSmall?.copyWith(color: onAppBarColor)),
        backgroundColor: appBarColor,
        elevation: 1,
        shadowColor: Colors.black.withAlpha(50),
        iconTheme: IconThemeData(color: onAppBarColor),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () => themeNotifier.toggleTheme(theme.brightness),
            color: onAppBarColor,
          ),
        ],
      ),
      body: Stack(
        children: [
          ArtisticBackground(shapes: forgotPasswordPattern),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                child: viewModel.state == ViewState.success
                    ? _buildSuccessView(context)
                    : _buildFormView(context, viewModel),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormView(BuildContext context, ForgotPasswordViewModel viewModel) {
    final textTheme = Theme.of(context).textTheme;
    final bool isLoading = viewModel.state == ViewState.loading;

    return FadeTransition(
      key: const ValueKey('form_view'),
      opacity: _fadeAnimation,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.lock_reset_outlined, size: 50, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text('Reset Password', style: textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text('Masukkan email terdaftar Anda untuk menerima tautan reset password.', style: textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 32),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: isLoading ? null : (_) => _sendResetEmail(),
              decoration: const InputDecoration(labelText: 'Email Terdaftar', prefixIcon: Icon(Icons.email_outlined)),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Email tidak boleh kosong';
                final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+$");
                if (!emailRegex.hasMatch(value)) return 'Format email tidak valid';
                return null;
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : _sendResetEmail,
                child: isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Kirim Email Reset'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final successColor = Theme.of(context).extension<CustomColors>()?.success ?? Colors.green;
    return FadeTransition(key: const ValueKey('success_view'), opacity: _fadeAnimation, child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [Icon(Icons.mark_email_read_outlined, size: 70, color: successColor), const SizedBox(height: 24), Text('Email Terkirim!', style: textTheme.headlineSmall, textAlign: TextAlign.center), const SizedBox(height: 12), Text('Silakan periksa kotak masuk email Anda untuk melanjutkan proses reset password.', style: textTheme.bodyMedium, textAlign: TextAlign.center)]));
  }
}