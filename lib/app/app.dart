import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liburan_create/app/providers.dart';
import 'package:liburan_create/app/router.dart';
import 'package:liburan_create/core/constants/app_constants.dart';
import 'package:liburan_create/core/theme/app_theme.dart';
import 'package:liburan_create/l10n/app_localizations.dart';

class ReminderScheduleApp extends ConsumerWidget {
  const ReminderScheduleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<void> bootstrap = ref.watch(appBootstrapProvider);
    final Locale locale = ref.watch(appLocaleProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: AppTheme.light(),
      locale: locale,
      supportedLocales: const <Locale>[Locale('id'), Locale('en')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      onGenerateRoute: onGenerateAppRoute,
      initialRoute: AppRoutes.home,
      builder: (BuildContext context, Widget? child) {
        return bootstrap.when(
          data: (_) => child ?? const SizedBox.shrink(),
          loading: () => const _BootstrapLoadingView(),
          error: (Object err, StackTrace _) => _BootstrapErrorView(error: err),
        );
      },
    );
  }
}

class _BootstrapLoadingView extends StatelessWidget {
  const _BootstrapLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _BootstrapErrorView extends StatelessWidget {
  const _BootstrapErrorView({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Initialization error: $error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
