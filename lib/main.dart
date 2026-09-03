import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'data/local/local_finance_repository.dart';
import 'data/local/local_auth_repository.dart';
import 'data/ml/categorizer_store.dart';
import 'data/ml/naive_bayes_categorizer.dart';
import 'data/sync/mock_cloud_sync_service.dart';
import 'data/sync/sync_metadata_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  final repository = await LocalFinanceRepository.open();
  final authRepository = LocalAuthRepository();
  final categorizer = await NaiveBayesCategorizer.load(
    await HiveCategorizerStore.open(),
  );
  final syncMetadataStore = await HiveSyncMetadataStore.open();
  runApp(NorteApp(
    repository: repository,
    authRepository: authRepository,
    categorizer: categorizer,
    cloudSyncService: MockCloudSyncService(),
    syncMetadataStore: syncMetadataStore,
  ));
}
