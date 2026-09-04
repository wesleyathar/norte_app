/// Resultado da conexão bem-sucedida no widget Pluggy Connect.
class PluggyConnectResult {
  const PluggyConnectResult({required this.itemId, this.connectorName});

  final String itemId;
  final String? connectorName;
}

/// Lançada quando o usuário fecha o widget sem concluir a conexão.
class PluggyConnectCancelled implements Exception {
  const PluggyConnectCancelled();
}

/// Lançada quando o widget reporta erro durante a conexão.
class PluggyConnectException implements Exception {
  const PluggyConnectException(this.message);

  final String message;

  @override
  String toString() => 'PluggyConnectException: $message';
}
