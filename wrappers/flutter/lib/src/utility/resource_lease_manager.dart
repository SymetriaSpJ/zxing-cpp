import 'dart:async';
import 'dart:developer' as dev;
import 'dart:collection';

/// Asynchronous factory invoked when a lease becomes active.
///
/// - Called when the lease reaches the front of the queue.
/// - Should return a ready‑to‑use resource (e.g. an initialized camera controller).
/// - May be wrapped by the manager's `createTimeout`.
typedef ResourceFactory<T> = Future<T> Function();

/// Function that releases the resource after the lease ends.
///
/// - Invoked exactly once for each created resource.
/// - Must fully and safely release the resource (e.g. `dispose`).
/// - May be wrapped by the manager's `releaseTimeout`.
typedef ResourceReleaser<T> = Future<void> Function(T resource);

/// Logger interface — allows injecting a custom logger.
typedef ResourceLogger = void Function(String message, Object? error, StackTrace? stackTrace);

/// Manager that provides exclusive (sequential) access to a resource via leases.
///
/// How it works:
/// - Only one lease can be active at a time; others wait in a FIFO queue.
/// - When a lease becomes active, the manager calls the `ResourceFactory`, then
///   completes `lease.resource`. Use the resource only within that lease window.
/// - When finished, call `lease.release()` / `lease.releaseWaiting()`; the manager
///   calls the `ResourceReleaser` and moves to the next lease.
/// - If a lease is released before the resource is created, creation is skipped.
/// - Optional `createTimeout` / `releaseTimeout` protect against hangs.
///
/// Typical use: serialize access to `CameraController` / `MobileScannerController`.
/// Prevents concurrent camera use and simplifies the resource life cycle.
class ResourceLeaseManager {
  ResourceLeaseManager({
    ResourceLogger? logger,
    this.createTimeout,
    this.releaseTimeout,
    this.maxQueueLength,
  }) : _logger = logger;

  final _leases = ListQueue<ResourceLease>();
  final ResourceLogger? _logger;
  final Duration? createTimeout;
  final Duration? releaseTimeout;
  final int? maxQueueLength;

  /// Number of items in the queue (active + pending).
  int get queueLength => _leases.length;

  /// Whether there is an active or pending lease.
  bool get hasActiveLease => _leases.isNotEmpty;

  void _log(String component, String message, {Object? error, StackTrace? stackTrace, int level = 800}) {
    final formatted = '[$component] $message';
    _logger?.call(formatted, error, stackTrace);
    dev.log(message, name: component, level: level, error: error, stackTrace: stackTrace);
  }

  /// Creates a new lease and enqueues it.
  ///
  /// - Returns a `ResourceLease<T>` handle exposing `Future<T> resource`.
  /// - The resource is created only when the lease reaches the front of the queue.
  /// - Throws `ResourceLeaseManagerException` if `maxQueueLength` is exceeded.
  ResourceLease<T> lease<T extends Object>({required ResourceFactory<T> create, required ResourceReleaser<T> release}) {
    _log('ResourceLeaseManager', 'lease<$T> requested');
    final lease = ResourceLease<T>._(create, release, this);
    if (_leases.isEmpty) {
      _leases.add(lease);
      _log('ResourceLeaseManager', 'lease enqueued and scheduled; lease=$lease, queue_len=${_leases.length}');
      unawaited(_processLease(lease));
    } else {
      if (_leases.length == maxQueueLength) {
        throw ResourceLeaseManagerException('Queue length exceeded');
      }
      _leases.add(lease);
      _log('ResourceLeaseManager', 'lease enqueued; lease=$lease, queue_len=${_leases.length}');
    }

    return lease;
  }

  Future<void> _processLease<T extends Object>(ResourceLease<T> lease) async {
    try {
      if (!lease.isReleased) {
        _log('ResourceLeaseManager', 'processing lease; lease=$lease, queue_len=${_leases.length}');
        await lease._openResource();
        _log('ResourceLeaseManager', 'awaiting lease release; lease=$lease');
        await lease._untilReleased();
        _log('ResourceLeaseManager', 'lease released; lease=$lease');
      } else {
        _log('ResourceLeaseManager', 'lease already released before open; skipping; lease=$lease');
      }
    } catch (e, st) {
      _log('ResourceLeaseManager', 'process lease failed; lease=$lease', error: e, stackTrace: st, level: 1000);
      throw StateError('Error occurred while processing $lease');
    } finally {
      _dequeueChecked(lease);

      _log('ResourceLeaseManager', 'lease dequeued; lease=$lease, queue_len=${_leases.length}');
      lease._markDequeued();

      final next = _leases.firstOrNull;
      if (next != null) {
        _log('ResourceLeaseManager', 'scheduling next lease; next=$next, queue_len=${_leases.length}');
        scheduleMicrotask(() => _processLease(next));
      }
    }
  }

  void _dequeueChecked(ResourceLease lease) {
    final removed = _leases.remove(lease);
    if (!removed) {
      _log('ResourceLeaseManager', 'queue desynchronization: failed to remove lease; lease=$lease', level: 1000);
      throw StateError('Queue desynchronization: failed to remove lease from queue');
    }
  }
}

/// Lease handle representing an exclusive right to use a resource.
///
/// Life cycle:
/// - Created via `ResourceLeaseManager.lease(...)` and enqueued.
/// - When it reaches the front, `resource` completes with the created value.
/// - When done, call `release()` / `releaseWaiting()` to free the resource and
///   unblock the next lease.
///
/// Tips:
/// - Always release the lease (e.g. in a widget's `dispose` or a `finally`).
/// - If you release before the resource is created, creation is skipped.
final class ResourceLease<T extends Object> {
  ResourceLease._(this._createCallback, this._releaseCallback, this._parent) : _id = Object().hashCode;

  final int _id;
  final ResourceLeaseManager _parent;

  final ResourceFactory<T> _createCallback;
  final ResourceReleaser<T> _releaseCallback;

  final _completer = Completer<T>();
  final _releaseCompleter = Completer<void>();
  final _dequeuedCompleter = Completer<void>();

  /// Whether the resource has been created (`resource` is completed).
  bool get isCompleted => _completer.isCompleted;

  /// Whether the lease has been released.
  bool get isReleased => _releaseCompleter.isCompleted;

  T? _value;

  /// Direct access to the resource after creation (may be `null` until ready).
  T? get value => _value;

  bool _isTimedOut = false;

  /// Whether the open operation exceeded the timeout.
  bool get isTimedOut => _isTimedOut;

  /// Completes when the resource is created and ready for use.
  Future<T> get resource => _completer.future;

  Future<void> _openResource() async {
    if (isCompleted) throw StateError('The $this was already completed');
    _parent._log('ResourceLease', 'creating resource; lease=$this');

    const tag = '_openResource';

    final value = _value = await _withTimeout(
      _measureTime(_createCallback(), tag),
      _parent.createTimeout,
      tag,
    );

    if (value != null) {
      _completer.complete(value);
    } else {
      _isTimedOut = true;
      final error = ResourceLeaseManagerException('Open timeout; lease=$this');
      _parent._log('ResourceLease', 'open timeout; lease=$this', error: error, stackTrace: StackTrace.current, level: 1000);
      _completer.completeError(error);
    }
  }

  Future<void> _release() => Future.microtask(() async {
    if (isReleased) return;

    const tag = '_release';

    try {
      if (value case final value?) {
        _parent._log('ResourceLease', 'releasing resource; lease=$this');
        await _withTimeout(
          _measureTime(_releaseCallback(value), tag),
          _parent.releaseTimeout,
          tag,
        );
      } else {
        _parent._log('ResourceLease', 'released before resource creation; no-op; lease=$this');
      }
    } catch (e, st) {
      _parent._log(
        'ResourceLease',
        'release failed; lease=$this. Resource may be left in inconsistent state',
        error: e,
        stackTrace: st,
        level: 1000,
      );
    } finally {
      if (!isReleased) {
        _releaseCompleter.complete();
      }
    }
  });

  Future<void> _untilReleased() async {
    if (isTimedOut) return;
    return _releaseCompleter.future;
  }

  Future<R?> _withTimeout<R>(Future<R> future, Duration? timeout, String tag) async {
    if (timeout == null) return future;

    final watchdogTimer = Timer(timeout * 0.75, () {
      _parent._log('ResourceLease', 'operation nearing timeout; lease=$this, op=$tag, timeout=${timeout.inMilliseconds}ms', level: 900);
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
      _parent._log('ResourceLease', 'elapsed=${stopwatch.elapsed} op=$tag lease=$this');
    }
  }

  /// Releases the lease asynchronously. Errors are logged; the queue continues.
  void release() => unawaited(releaseWaiting());

  /// Releases the lease and returns a `Future` that completes when the resource
  /// has been fully released.
  Future<void> releaseWaiting() async {
    await _release();
    if (!_dequeuedCompleter.isCompleted) {
      await _dequeuedCompleter.future;
    }
  }

  void _markDequeued() {
    if (!_dequeuedCompleter.isCompleted) {
      _dequeuedCompleter.complete();
    }
  }

  @override
  int get hashCode => _id;

  @override
  bool operator ==(Object other) => other is ResourceLease<T> && other.hashCode == hashCode;

  @override
  String toString() {
    return 'ResourceLease<$T>(#$_id)';
  }
}

/// Error thrown by the lease manager — e.g. queue limit exceeded or timeouts.
final class ResourceLeaseManagerException implements Exception {
  const ResourceLeaseManagerException([this.message]);

  final String? message;

  @override
  String toString() {
    return '$ResourceLeaseManagerException: ${message ?? 'unknown'}';
  }
}
