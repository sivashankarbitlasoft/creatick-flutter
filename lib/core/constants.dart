/// Change this to match where your FastAPI backend is running.
///
/// - Android emulator: FastAPI running on your computer -> use 10.0.2.2
/// - iOS simulator: FastAPI running on your computer -> use 127.0.0.1 or localhost
/// - Physical phone (real device): use your computer's LAN IP, e.g. 192.168.1.5
///   (phone and computer must be on the same Wi-Fi network)
class ApiConstants {
  static const String baseUrl = 'http://10.0.2.2:8000';
}
