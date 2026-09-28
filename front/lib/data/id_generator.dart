import 'dart:math';

/// Generates locally-unique ids for `tmp_*` entity ids and `client_op_id`s.
/// Not cryptographically secure — uniqueness across a single client is the
/// only requirement (the server allocates real entity ids on apply).
class IdGenerator {
  IdGenerator([Random? random]) : _random = random ?? Random();

  final Random _random;

  /// Returns an opaque id like `1735689600000123-abc12`.
  String next() {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final r = _random.nextInt(1 << 30).toRadixString(36);
    return '$ts-$r';
  }

  /// Convenience: returns a tmp entity id with the protocol's `tmp_` prefix.
  String nextTmpId() => 'tmp_${next()}';
}
