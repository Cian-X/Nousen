import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liburan_create/app/providers.dart';
import 'package:liburan_create/features/activity/domain/activity_model.dart';
import 'package:liburan_create/features/activity/presentation/activity_detail_page.dart';
import 'package:liburan_create/features/activity/presentation/activity_form_page.dart';
import 'package:liburan_create/features/home/presentation/home_shell_page.dart';
import 'package:liburan_create/features/one_time_reminder/presentation/one_time_reminder_detail_page.dart';
import 'package:liburan_create/features/settings/domain/app_settings_model.dart';
import 'package:liburan_create/features/settings/presentation/initial_setup_onboarding_page.dart';
import 'package:liburan_create/features/stats/presentation/stats_page.dart';

class AppRoutes {
  static const String home = '/';
  static const String createActivity = '/create-activity';
  static const String activityDetail = '/activity-detail';
  static const String activitySummary = '/activity-summary';
  static const String statsReport = '/stats-report';
  static const String oneTimeReminderDetail = '/one-time-reminder-detail';
}

class CreateActivityArgs {
  const CreateActivityArgs({this.activity});

  final ActivityModel? activity;
}

class ActivityDetailArgs {
  const ActivityDetailArgs({required this.activityId, this.scheduledDate});

  final String activityId;
  final DateTime? scheduledDate;
}

class OneTimeReminderDetailArgs {
  const OneTimeReminderDetailArgs({required this.reminderId});

  final String reminderId;
}

Route<dynamic> onGenerateAppRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.home:
      return MaterialPageRoute<void>(builder: (_) => const _AppEntryPage());
    case AppRoutes.createActivity:
      return MaterialPageRoute<void>(
        builder: (_) =>
            CreateActivityPage(args: settings.arguments as CreateActivityArgs?),
      );
    case AppRoutes.activityDetail:
      return MaterialPageRoute<void>(
        builder: (_) =>
            ActivityDetailPage(args: settings.arguments! as ActivityDetailArgs),
      );
    case AppRoutes.activitySummary:
      return MaterialPageRoute<void>(builder: (_) => const StatsPage());
    case AppRoutes.statsReport:
      return MaterialPageRoute<void>(
        builder: (_) => StatsReportPage(
          dailyStats: (settings.arguments as Map<String, dynamic>)['dailyStats'],
          periodActivityStats: (settings.arguments as Map<String, dynamic>)['periodActivityStats'],
          start: (settings.arguments as Map<String, dynamic>)['start'],
          end: (settings.arguments as Map<String, dynamic>)['end'],
          totalScheduled: (settings.arguments as Map<String, dynamic>)['totalScheduled'],
          localeCode: (settings.arguments as Map<String, dynamic>)['localeCode'],
        ),
      );
    case AppRoutes.oneTimeReminderDetail:
      return MaterialPageRoute<void>(
        builder: (_) => OneTimeReminderDetailPage(
          args: settings.arguments! as OneTimeReminderDetailArgs,
        ),
      );
    default:
      return MaterialPageRoute<void>(builder: (_) => const _AppEntryPage());
  }
}

class _AppEntryPage extends ConsumerStatefulWidget {
  const _AppEntryPage();

  @override
  ConsumerState<_AppEntryPage> createState() => _AppEntryPageState();
}

class _AppEntryPageState extends ConsumerState<_AppEntryPage> {
  @override
  Widget build(BuildContext context) {
    final AsyncValue<AppSettingsModel> settingsAsync = ref.watch(
      settingsStreamProvider,
    );

    return settingsAsync.when(
      loading: () => const _AppEntryLoadingView(),
      error: (_, _) => const HomeShellPage(),
      data: (settings) {
        if (settings.needsInitialUserSetup) {
          return const InitialSetupOnboardingPage();
        }

        return const HomeShellPage();
      },
    );
  }
}

class _AppEntryLoadingView extends StatelessWidget {
  const _AppEntryLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator.adaptive(),
      ),
    );
  }
}
