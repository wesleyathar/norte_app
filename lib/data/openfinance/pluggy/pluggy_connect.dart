import 'pluggy_connect_result.dart';

export 'pluggy_connect_result.dart';

// Seleciona a implementação real (web) ou o stub conforme a plataforma.
import 'pluggy_connect_stub.dart'
    if (dart.library.js_interop) 'pluggy_connect_web.dart' as impl;

Future<PluggyConnectResult> launchPluggyConnect(String connectToken) =>
    impl.launchPluggyConnect(connectToken);
