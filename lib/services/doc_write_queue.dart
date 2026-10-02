import 'dart:async';

Future<void> _pending = Future.value();

/// Imports and Drive downloads share a store; serialize name allocation and
/// writes so two operations cannot claim the same destination or replace it.
Future<T> inDocWriteQueue<T>(Future<T> Function() work) async {
  final before = _pending;
  final done = Completer<void>();
  _pending = done.future;
  await before;
  try {
    return await work();
  } finally {
    done.complete();
  }
}
