import 'pluggy_connect_result.dart';

export 'pluggy_connect_result.dart';

/// Abre o widget Pluggy Connect e resolve com o item conectado.
///
/// A implementação real (interop JS) só existe na web; nas demais plataformas
/// usa-se o stub, que lança [UnsupportedError].
Future<PluggyConnectResult> launchPluggyConnect(String connectToken) =>
    throw UnsupportedError(
      'O Pluggy Connect só está disponível na versão web do Norte.',
    );
