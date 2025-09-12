import 'dart:async';
import 'dart:developer' as dev;
import 'dart:collection';

typedef ResourceFactory<T> = Future<T> Function();
typedef ResourceReleaser<T> = Future<void> Function(T resource);
typedef ResourceLogger = void Function(String message, Object? error, StackTrace? stackTrace);

class ResourceLeaseManager {
  ResourceLeaseManager({ResourceLogger? logger, this.createTimeout, this.releaseTimeout, this.maxQueueLength}) : _logger = logger;

  final _leases = ListQueue<ResourceLease>();
  final ResourceLogger? _logger;
  final Duration? createTimeout;
  final Duration? releaseTimeout;
  final int? maxQueueLength;

  int get queueLength => _leases.length;
  bool get hasActiveLease => _leases.isNotEmpty;

  void _log(String message, [Object? error, StackTrace? stackTrace]) {
    _logger?.call(message, error, stackTrace);
    dev.log(message, error: error, stackTrace: stackTrace);
  }

  ResourceLease<T> lease<T extends Object>({required ResourceFactory<T> create, required ResourceReleaser<T> release}) {
    _log('$ResourceLeaseManager.lease<$T>');
    final lease = ResourceLease<T>._(create, release, this);
    if (_leases.isEmpty) {
      _log('Queue is empty, scheduled lease - $lease');
      _leases.add(lease);
      unawaited(_processLease(lease));
    } else {
      if (_leases.length == maxQueueLength) {
        throw ResourceLeaseManagerException('❌ Queue length exceeded');
      }
      _log('Lease queued - $lease');
      _leases.add(lease);
    }

    return lease;
  }

  Future<void> _processLease<T extends Object>(ResourceLease<T> lease) async {
    try {
      if (!lease.isReleased) {
        _log('Processing lease - $lease');
        await lease._openResource();
        _log('Waiting for lease release - $lease');
        await lease._untilReleased();
        _log('Lease released - $lease');
        _log('____________________________________________');
      } else {
        _log('Lease already released, skipping - $lease');
      }
    } catch (e, st) {
      _log('_processLease error', e, st);
      throw StateError('Error occurred while processing $lease');
    } finally {
      _dequeueChecked(lease);

      final next = _leases.firstOrNull;
      if (next != null) {
        _log('Scheduled next lease - $next');
        await _processLease(next);
      }
    }
  }

  void _dequeueChecked(ResourceLease lease) {
    final removed = _leases.remove(lease);
    if (!removed) {
      throw StateError('Error occurred while removing lease from queue');
    }
  }
}

final class ResourceLease<T extends Object> {
  ResourceLease._(this._createCallback, this._releaseCallback, this._parent) : _id = Object().hashCode;

  final int _id;
  final ResourceLeaseManager _parent;

  final ResourceFactory<T> _createCallback;
  final ResourceReleaser<T> _releaseCallback;

  final _completer = Completer<T>();
  final _releaseCompleter = Completer();

  bool get isCompleted => _completer.isCompleted;
  bool get isReleased => _releaseCompleter.isCompleted;

  T? _value;
  T? get value => _value;

  bool _isTimedOut = false;
  bool get isTimedOut => _isTimedOut;

  Future<T> get resource => _completer.future;

  Future<void> _openResource() async {
    if (isCompleted) throw StateError('The $this was already completed');
    _parent._log('Creating resource - $this ...');

    const tag = '_openResource';

    final value = _value = await _withTimeout(_measureTime(_createCallback(), tag), _parent.createTimeout, tag);

    if (value != null) {
      _completer.complete(value);
    } else {
      _isTimedOut = true;
      final error = ResourceLeaseManagerException('Timeout - $this');
      _parent._log('_openResource timeout - $this', error, StackTrace.current);
      _completer.completeError(error);
    }
  }

  Future<void> _release() async {
    const tag = '_release';

    try {
      if (value case final value?) {
        _parent._log('Releasing resource - $this ...');
        await _withTimeout(_measureTime(_releaseCallback(value), tag), _parent.releaseTimeout, tag);
      } else {
        _parent._log('✅ Lease released before resource was created - $this');
      }
    } catch (e, st) {
      _parent._log('Error occurred while releasing lease - $this. This can lead to unexpected behaviours', e, st);
    } finally {
      if (!isReleased) {
        _releaseCompleter.complete();
      }
    }
  }

  Future<void> _untilReleased() async {
    if (isTimedOut) return;
    return _releaseCompleter.future;
  }

  Future<R?> _withTimeout<R>(Future<R> future, Duration? timeout, String tag) async {
    if (timeout == null) return future;

    final watchdogTimer = Timer(timeout * 0.75, () {
      _parent._log('⚠️ Operation is close to reach the timeout - $this - #$tag');
    });

    try {
      return await future.timeout(timeout);
    } on TimeoutException catch (_) {
      return null;
    } finally {
      watchdogTimer.cancel();
    }
  }

  Future<R> _measureTime<R>(Future<R> future, String tag) async {
    final stopwatch = Stopwatch()..start();
    try {
      return await future;
    } finally {
      stopwatch.stop();
      _parent._log('⏱️ Elapsed - ${stopwatch.elapsed} - $this - #$tag');
    }
  }

  void release() => unawaited(releaseWaiting());

  Future<void> releaseWaiting() => _release();

  @override
  int get hashCode => _id;

  @override
  bool operator ==(Object other) => other is ResourceLease<T> && other.hashCode == hashCode;

  @override
  String toString() {
    return 'ResourceLease<$T>(#$_id)';
  }
}

final class ResourceLeaseManagerException implements Exception {
  const ResourceLeaseManagerException([this.message]);

  final String? message;

  @override
  String toString() {
    return '$ResourceLeaseManagerException: ${message ?? 'unknown'}';
  }
}
