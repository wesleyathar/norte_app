import 'dart:async';
import 'dart:js_interop';

import 'pluggy_connect_result.dart';

export 'pluggy_connect_result.dart';

@JS('PluggyConnect')
extension type _PluggyConnect._(JSObject _) implements JSObject {
  external factory _PluggyConnect(_PluggyConnectOptions options);
  external void init();
}

extension type _PluggyConnectOptions._(JSObject _) implements JSObject {
  external factory _PluggyConnectOptions({
    String connectToken,
    bool includeSandbox,
    JSFunction onSuccess,
    JSFunction onError,
    JSFunction onClose,
  });
}

extension type _PluggyItemData._(JSObject _) implements JSObject {
  external _PluggyItem? get item;
}

extension type _PluggyItem._(JSObject _) implements JSObject {
  external String get id;
  external _PluggyConnector? get connector;
}

extension type _PluggyConnector._(JSObject _) implements JSObject {
  external String? get name;
}

/// Abre o widget Pluggy Connect na web e resolve com o item conectado.
Future<PluggyConnectResult> launchPluggyConnect(String connectToken) {
  final completer = Completer<PluggyConnectResult>();

  void onSuccess(JSObject data) {
    if (completer.isCompleted) return;
    final itemData = data as _PluggyItemData;
    final item = itemData.item;
    if (item == null) {
      completer.completeError(
        const PluggyConnectException('Item não retornado pelo Pluggy.'),
      );
      return;
    }
    completer.complete(
      PluggyConnectResult(itemId: item.id, connectorName: item.connector?.name),
    );
  }

  void onError(JSObject _) {
    if (completer.isCompleted) return;
    completer.completeError(
      const PluggyConnectException('Falha na conexão com o Pluggy.'),
    );
  }

  void onClose() {
    if (completer.isCompleted) return;
    completer.completeError(const PluggyConnectCancelled());
  }

  final widget = _PluggyConnect(
    _PluggyConnectOptions(
      connectToken: connectToken,
      includeSandbox: true,
      onSuccess: onSuccess.toJS,
      onError: onError.toJS,
      onClose: onClose.toJS,
    ),
  );
  widget.init();

  return completer.future;
}
