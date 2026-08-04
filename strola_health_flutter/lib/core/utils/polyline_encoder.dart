import 'package:latlong2/latlong.dart';

/// Standard Google polyline algorithm encoder — matches what the backend's
/// `route_polyline` field expects (an encoded string, not a raw point
/// list/array), so a session's GPS route round-trips through Firestore the
/// same way it would through any Maps API that consumes this format.
String encodePolyline(List<LatLng> points) {
  final buffer = StringBuffer();
  var prevLat = 0;
  var prevLng = 0;
  for (final p in points) {
    final lat = (p.latitude * 1e5).round();
    final lng = (p.longitude * 1e5).round();
    _encodeValue(lat - prevLat, buffer);
    _encodeValue(lng - prevLng, buffer);
    prevLat = lat;
    prevLng = lng;
  }
  return buffer.toString();
}

void _encodeValue(int value, StringBuffer buffer) {
  var v = value < 0 ? ~(value << 1) : (value << 1);
  while (v >= 0x20) {
    buffer.writeCharCode((0x20 | (v & 0x1f)) + 63);
    v >>= 5;
  }
  buffer.writeCharCode(v + 63);
}
