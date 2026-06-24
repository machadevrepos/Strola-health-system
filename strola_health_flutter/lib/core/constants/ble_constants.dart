/// Nordic UART Service (NUS) UUIDs exposed by the nRF5340 firmware.
/// Device: NRF7002 DK  |  OS: Zephyr RTOS  |  IMU: MPU-6050 via I2C
class BleConstants {
  BleConstants._();

  static const String deviceName = 'NRF7002_STEPS';

  // NUS service + characteristics (standard Nordic UUIDs, lowercase for flutter_reactive_ble)
  static const String serviceUuid = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
  static const String txCharUuid =
      '6e400003-b5a3-f393-e0a9-e50e24dcca9e'; // firmware → phone (notify)
  static const String rxCharUuid =
      '6e400002-b5a3-f393-e0a9-e50e24dcca9e'; // phone → firmware (write)

  // Reconnection backoff settings
  static const int maxReconnectAttempts = 6;
  static const int scanTimeoutSeconds = 15;

  // Step data packet formats the parser handles:
  //   • 4 bytes  → uint32 little-endian  (Zephyr default for uint32_t)
  //   • 2 bytes  → uint16 little-endian
  //   • N bytes  → ASCII/UTF-8 string (e.g. "1234\n")
}
