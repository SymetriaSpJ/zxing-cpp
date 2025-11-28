import 'dart:async';

import 'package:fitatu_barcode_scanner/src/utility/resource_lease_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResourceLeaseManager', () {
    test('creates and releases a single lease', () async {
      final manager = ResourceLeaseManager();
      var created = 0;
      var released = 0;

      final lease = manager.lease<int>(
        create: () async {
          created++;
          return 42;
        },
        release: (value) async {
          released++;
        },
      );

      final value = await lease.resource;
      expect(value, 42);
      expect(created, 1);
      expect(manager.queueLength, 1); // active lease in queue

      await lease.releaseWaiting();
      expect(released, 1);
      expect(manager.queueLength, 0);
      expect(manager.hasActiveLease, isFalse);
    });

    test('queues subsequent leases until previous released (FIFO)', () async {
      final manager = ResourceLeaseManager();
      final events = <String>[];

      final lease1 = manager.lease<String>(
        create: () async {
          events.add('create1');
          return 'r1';
        },
        release: (value) async {
          events.add('release1');
        },
      );

      final lease2 = manager.lease<String>(
        create: () async {
          events.add('create2');
          return 'r2';
        },
        release: (value) async {
          events.add('release2');
        },
      );

      final r1 = await lease1.resource;
      expect(r1, 'r1');
      expect(events, contains('create1'));
      expect(events, isNot(contains('create2')));

      await lease1.releaseWaiting();

      final r2 = await lease2.resource;
      expect(r2, 'r2');
      // Ensure ordering: create2 happens after release1
      expect(events.indexOf('create2'), greaterThan(events.indexOf('release1')));
    });

    test('releaseWaiting completes after release callback finishes', () async {
      final manager = ResourceLeaseManager();
      final events = <String>[];
      final completer = Completer<void>();

      final lease = manager.lease<String>(
        create: () async => 'ok',
        release: (value) async {
          events.add('release_cb_start');
          await completer.future;
          events.add('release_cb_done');
        },
      );

      await lease.resource;

      // Start releasing but hold release callback until we complete the completer.
      final releaseFuture = lease.releaseWaiting();

      // Let the event loop spin a bit.
      await Future<void>.delayed(Duration(milliseconds: 10));
      expect(events, contains('release_cb_start'));
      expect(events, isNot(contains('release_cb_done')));

      completer.complete();
      await releaseFuture;
      expect(events, contains('release_cb_done'));
    });

    test('create timeout errors the lease and moves on to next', () async {
      final manager = ResourceLeaseManager(
        createTimeout: const Duration(milliseconds: 50),
      );

      final lease1 = manager.lease<int>(
        create: () async {
          // Exceeds createTimeout
          await Future<void>.delayed(const Duration(milliseconds: 200));
          return 1;
        },
        release: (v) async {},
      );

      final lease2 = manager.lease<int>(
        create: () async => 2,
        release: (v) async {},
      );

      var lease1Errored = false;
      // Observe error without throwing in test
      unawaited(
        lease1.resource.catchError((_) {
          lease1Errored = true;
          return 0; // satisfy Future<int> catchError type
        }),
      );

      // Allow time for timeout to trigger and next lease to start
      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(lease1.isTimedOut, isTrue);
      expect(lease1Errored, isTrue);

      final value2 = await lease2.resource;
      expect(value2, 2);
    });

    test('release timeout allows queue to proceed', () async {
      final manager = ResourceLeaseManager(
        releaseTimeout: const Duration(milliseconds: 50),
      );

      final lease1 = manager.lease<int>(
        create: () async => 1,
        release: (v) async {
          // Exceeds timeout
          await Future<void>.delayed(const Duration(milliseconds: 200));
        },
      );

      final lease2 = manager.lease<int>(
        create: () async => 2,
        release: (v) async {},
      );

      await lease1.resource;
      lease1.release();

      // Allow time for release timeout and next lease to start
      await Future<void>.delayed(const Duration(milliseconds: 120));

      final v2 = await lease2.resource;
      expect(v2, 2);
    });

    test('maxQueueLength is enforced', () async {
      final manager = ResourceLeaseManager(maxQueueLength: 1);

      // First lease enqueued
      manager.lease<int>(create: () async => 1, release: (v) async {});

      // Second should throw
      expect(
        () => manager.lease<int>(create: () async => 2, release: (v) async {}),
        throwsA(isA<ResourceLeaseManagerException>()),
      );
    });

    test('releasing before creation completes runs callback', () async {
      final manager = ResourceLeaseManager(maxQueueLength: 1);

      bool created = false;
      bool released = false;

      final lease = manager.lease<int>(
        create: () async {
          await Future.delayed(Duration(milliseconds: 100));
          created = true;
          return 0;
        },
        release: (resource) async {
          released = true;
        },
      )..release();

      await lease.resource;
      await lease.releaseWaiting();

      expect(created, isTrue, reason: "The `create` callback was not called");
      expect(released, isTrue, reason: "The `release` callback was not called");
    });
  });
}
