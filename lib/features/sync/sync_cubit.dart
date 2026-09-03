import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/sync/sync_metadata_store.dart';
import '../../domain/repositories/finance_repository.dart';
import '../../domain/sync/cloud_sync_service.dart';

enum SyncStatus { idle, syncing, success, failure }

/// Resultado da última reconciliação com a nuvem.
enum SyncOutcome { none, pushed, pulled, alreadyInSync }

class SyncState {
  const SyncState({
    this.status = SyncStatus.idle,
    this.outcome = SyncOutcome.none,
    this.lastSyncedAt,
    this.error,
  });

  final SyncStatus status;
  final SyncOutcome outcome;
  final DateTime? lastSyncedAt;
  final String? error;

  bool get isSyncing => status == SyncStatus.syncing;

  /// Sinaliza que a UI deve recarregar os dados locais após um download.
  bool get didPull => status == SyncStatus.success && outcome == SyncOutcome.pulled;

  SyncState copyWith({
    SyncStatus? status,
    SyncOutcome? outcome,
    DateTime? lastSyncedAt,
    String? error,
  }) {
    return SyncState(
      status: status ?? this.status,
      outcome: outcome ?? this.outcome,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      error: error,
    );
  }
}

/// Reconcilia o estado local com a nuvem usando um contador de revisão.
///
/// Regra: se a revisão remota está à frente da base local, baixa (a nuvem tem
/// mudanças de outro dispositivo). Caso contrário, se houve alteração local,
/// envia. Se nada mudou, apenas confirma que já está sincronizado.
class SyncCubit extends Cubit<SyncState> {
  SyncCubit(this._repository, this._service, this._metadataStore)
      : super(const SyncState());

  final FinanceRepository _repository;
  final CloudSyncService _service;
  final SyncMetadataStore _metadataStore;

  Future<void> loadLastSynced() async {
    final metadata = await _metadataStore.read();
    emit(state.copyWith(lastSyncedAt: metadata.lastSyncedAt));
  }

  Future<void> synchronize() async {
    if (state.isSyncing) return;
    emit(state.copyWith(status: SyncStatus.syncing, error: null));

    try {
      final metadata = await _metadataStore.read();
      final remote = await _service.download();
      final snapshot = await _repository.load();
      final localHash = _hash(snapshot.toJson());
      final now = DateTime.now();

      if (remote != null && remote.revision > metadata.baseRevision) {
        // A nuvem está à frente: baixa e sobrescreve o estado local.
        await _repository.replaceAll(FinanceSnapshot.fromJson(remote.data));
        await _metadataStore.write(
          metadata.copyWith(
            baseRevision: remote.revision,
            lastSyncedAt: now,
            lastSyncedHash: _hash(remote.data),
          ),
        );
        _emitSuccess(SyncOutcome.pulled, now);
        return;
      }

      final hasLocalChanges =
          remote == null || localHash != metadata.lastSyncedHash;
      if (hasLocalChanges) {
        final revision = (remote?.revision ?? 0) + 1;
        await _service.upload(
          CloudSnapshot(
            deviceId: metadata.deviceId,
            revision: revision,
            updatedAt: now,
            data: snapshot.toJson(),
          ),
        );
        await _metadataStore.write(
          metadata.copyWith(
            baseRevision: revision,
            lastSyncedAt: now,
            lastSyncedHash: localHash,
          ),
        );
        _emitSuccess(SyncOutcome.pushed, now);
        return;
      }

      await _metadataStore.write(metadata.copyWith(lastSyncedAt: now));
      _emitSuccess(SyncOutcome.alreadyInSync, now);
    } on Exception catch (e) {
      emit(
        state.copyWith(
          status: SyncStatus.failure,
          error: 'Não foi possível sincronizar: $e',
        ),
      );
    }
  }

  void _emitSuccess(SyncOutcome outcome, DateTime at) {
    emit(
      state.copyWith(
        status: SyncStatus.success,
        outcome: outcome,
        lastSyncedAt: at,
      ),
    );
  }

  String _hash(Map<String, dynamic> data) =>
      sha256.convert(utf8.encode(json.encode(data))).toString();
}
