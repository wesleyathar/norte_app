import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'data/auth/firebase_account_auth_service.dart';
import 'data/local/local_auth_repository.dart';
import 'data/ml/categorizer_store.dart';
import 'data/ml/naive_bayes_categorizer.dart';
import 'data/remote/firestore_finance_repository.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('pt_BR');

  final repository = FirestoreFinanceRepository();
  final authRepository = LocalAuthRepository();
  final accountAuthService = FirebaseAccountAuthService();
  final categorizer = await NaiveBayesCategorizer.load(
    await HiveCategorizerStore.open(),
  );

  runApp(NorteApp(
    repository: repository,
    authRepository: authRepository,
    accountAuthService: accountAuthService,
    categorizer: categorizer,
  ));
}
