import 'io_get_api_key.dart' if (dart.library.html) 'web_get_api_key.dart';

String getApiKey() => platformGetApiKey();
