import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_motion.dart';
import '../core/theme/app_theme.dart';
import '../data/openfinance/mock_open_finance_service.dart';
import '../data/sync/mock_cloud_sync_service.dart';
import '../data/sync/sync_metadata_store.dart';
import '../domain/ml/transaction_categorizer.dart';
import '../domain/repositories/finance_repository.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/services/account_auth_service.dart';
import '../domain/services/open_finance_service.dart';
import '../domain/sync/cloud_sync_service.dart';
import '../features/finance/finance_cubit.dart';
import '../features/account/account_cubit.dart';
import '../features/auth/auth_cubit.dart';
import '../features/connections/connections_cubit.dart';
import '../features/sync/sync_cubit.dart';
import 'router.dart';

class NorteApp extends StatefulWidget {
  const NorteApp({
    super.key,
    required this.repository,
    required this.authRepository,
    required this.accountAuthService,
    this.openFinanceService = const MockOpenFinanceService(),
    this.categorizer,
    this.cloudSyncService,
    this.syncMetadataStore,
  });

  final FinanceRepository repository;
  final AuthRepository authRepository;
  final AccountAuthService accountAuthService;
  final OpenFinanceService openFinanceService;
  final TransactionCategorizer? categorizer;
  final CloudSyncService? cloudSyncService;
  final SyncMetadataStore? syncMetadataStore;

  @override
  State<NorteApp> createState() => _NorteAppState();
}

class _NorteAppState extends State<NorteApp> {
  late final AccountCubit _accountCubit = AccountCubit(widget.accountAuthService);
  late final GoRouter _router = createRouter(_accountCubit);
  final _motionSettings = MotionSettings();
  late final CloudSyncService _cloudSync =
      widget.cloudSyncService ?? MockCloudSyncService();
  late final SyncMetadataStore _syncMeta =
      widget.syncMetadataStore ?? InMemorySyncMetadataStore();

  @override
  void dispose() {
    _accountCubit.close();
    _motionSettings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _accountCubit),
        BlocProvider(
          create: (_) => AuthCubit(widget.authRepository)..initialize(),
        ),
        BlocProvider(
          create: (_) => FinanceCubit(widget.repository, widget.categorizer)
            ..load(),
        ),
        BlocProvider(
          create: (_) => ConnectionsCubit(
            widget.openFinanceService,
            widget.repository,
            widget.categorizer,
          ),
        ),
        BlocProvider(
          create: (_) => SyncCubit(
            widget.repository,
            _cloudSync,
            _syncMeta,
          )..loadLastSynced(),
        ),
      ],
      child: MotionSettingsScope(
        settings: _motionSettings,
        child: BlocListener<AccountCubit, AccountState>(
          listenWhen: (prev, curr) => prev.status != curr.status,
          listener: (context, state) {
            // Recarrega os dados financeiros ao trocar de sessão (login/logout).
            if (state.status != AccountStatus.unknown) {
              context.read<FinanceCubit>().load();
            }
          },
          child: MaterialApp.router(
            title: 'Norte',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeMode.system,
            routerConfig: _router,
            locale: const Locale('pt', 'BR'),
            supportedLocales: const [Locale('pt', 'BR')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          ),
        ),
      ),
    );
  }
}
