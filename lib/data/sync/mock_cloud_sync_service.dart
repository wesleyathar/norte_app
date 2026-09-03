import '../../domain/sync/cloud_sync_service.dart';

/// Backend de nuvem simulado em memória.
///
/// Reproduz a latência de rede e mantém um único snapshot, como faria um
/// documento por usuário em um serviço real (Firestore, Supabase, etc.).
class MockCloudSyncService implements CloudSyncService {
  MockCloudSyncService({this.latency = const Duration(milliseconds: 600)});

  final Duration latency;
  CloudSnapshot? _remote;

  @override
  Future<CloudSnapshot?> download() async {
    await Future<void>.delayed(latency);
    return _remote;
  }

  @override
  Future<void> upload(CloudSnapshot snapshot) async {
    await Future<void>.delayed(latency);
    // Serializa e reidrata para simular ida e volta pela rede.
    _remote = CloudSnapshot.fromJson(snapshot.toJson());
  }
}
