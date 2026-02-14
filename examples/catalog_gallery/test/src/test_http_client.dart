// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

class TestHttpClient implements io.HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Duration? connectionTimeout;

  @override
  Duration idleTimeout = const Duration(seconds: 15);

  @override
  int? maxConnectionsPerHost;

  @override
  String? userAgent;

  @override
  void addCredentials(
    Uri url,
    String realm,
    io.HttpClientCredentials credentials,
  ) {}

  @override
  void addProxyCredentials(
    String host,
    int port,
    String realm,
    io.HttpClientCredentials credentials,
  ) {}

  @override
  set authenticate(
    Future<bool> Function(Uri url, String scheme, String? realm)? f,
  ) {}

  @override
  set authenticateProxy(
    Future<bool> Function(String host, int port, String scheme, String? realm)?
    f,
  ) {}

  @override
  set badCertificateCallback(
    bool Function(io.X509Certificate cert, String host, int port)? callback,
  ) {}

  @override
  void close({bool force = false}) {}

  @override
  set findProxy(String Function(Uri url)? f) {}

  @override
  set keyLog(void Function(String line)? callback) {}

  @override
  Future<io.HttpClientRequest> open(
    String method,
    String host,
    int port,
    String path,
  ) async {
    return TestHttpClientRequest();
  }

  @override
  Future<io.HttpClientRequest> openUrl(String method, Uri url) {
    return open(method, url.host, url.port, url.path);
  }

  @override
  Future<io.HttpClientRequest> patch(String host, int port, String path) async {
    return TestHttpClientRequest();
  }

  @override
  Future<io.HttpClientRequest> patchUrl(Uri url) async {
    return TestHttpClientRequest();
  }

  @override
  Future<io.HttpClientRequest> post(String host, int port, String path) async {
    return TestHttpClientRequest();
  }

  @override
  Future<io.HttpClientRequest> postUrl(Uri url) async {
    return TestHttpClientRequest();
  }

  @override
  Future<io.HttpClientRequest> put(String host, int port, String path) async {
    return TestHttpClientRequest();
  }

  @override
  Future<io.HttpClientRequest> putUrl(Uri url) async {
    return TestHttpClientRequest();
  }

  @override
  Future<io.HttpClientRequest> delete(
    String host,
    int port,
    String path,
  ) async {
    return TestHttpClientRequest();
  }

  @override
  Future<io.HttpClientRequest> deleteUrl(Uri url) async {
    return TestHttpClientRequest();
  }

  @override
  Future<io.HttpClientRequest> get(String host, int port, String path) async {
    return TestHttpClientRequest();
  }

  @override
  Future<io.HttpClientRequest> getUrl(Uri url) async {
    return TestHttpClientRequest();
  }

  @override
  Future<io.HttpClientRequest> head(String host, int port, String path) async {
    return TestHttpClientRequest();
  }

  @override
  Future<io.HttpClientRequest> headUrl(Uri url) async {
    return TestHttpClientRequest();
  }

  @override
  set connectionFactory(
    Future<io.ConnectionTask<io.Socket>> Function(
      Uri url,
      String? proxyHost,
      int? proxyPort,
    )?
    f,
  ) {}
}

class TestHttpClientRequest implements io.HttpClientRequest {
  @override
  bool bufferOutput = true;

  @override
  int contentLength = 0;

  @override
  Encoding get encoding => utf8;

  @override
  set encoding(Encoding value) {}

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  bool persistentConnection = true;

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}

  @override
  void add(List<int> data) {}

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<List<int>> stream) async {}

  @override
  Future<io.HttpClientResponse> close() async {
    return TestHttpClientResponse();
  }

  @override
  io.HttpConnectionInfo? get connectionInfo => null;

  @override
  List<io.Cookie> get cookies => [];

  @override
  Future<io.HttpClientResponse> get done =>
      Future.value(TestHttpClientResponse());

  @override
  Future<void> flush() async {}

  @override
  io.HttpHeaders get headers => TestHttpHeaders();

  @override
  String get method => 'GET';

  @override
  Uri get uri => Uri.parse('http://localhost');

  @override
  void write(Object? object) {}

  @override
  void writeAll(Iterable<Object?> objects, [String separator = '']) {}

  @override
  void writeCharCode(int charCode) {}

  @override
  void writeln([Object? object = '']) {}
}

class TestHttpHeaders implements io.HttpHeaders {
  @override
  bool chunkedTransferEncoding = false;

  @override
  int contentLength = 0;

  @override
  io.ContentType? contentType;

  @override
  DateTime? date;

  @override
  DateTime? expires;

  @override
  String? host;

  @override
  DateTime? ifModifiedSince;

  @override
  bool persistentConnection = false;

  @override
  int? port;

  @override
  List<String> operator [](String name) => [];

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void clear() {}

  @override
  void forEach(void Function(String name, List<String> values) action) {}

  @override
  void noFolding(String name) {}

  @override
  void remove(String name, Object value) {}

  @override
  void removeAll(String name) {}

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  String? value(String name) => null;
}

class TestHttpClientResponse implements io.HttpClientResponse {
  final List<int> _imageData = base64Decode(
    '''iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=''',
  );
  @override
  io.X509Certificate? get certificate => null;

  @override
  io.HttpClientResponseCompressionState get compressionState =>
      io.HttpClientResponseCompressionState.notCompressed;

  @override
  io.HttpConnectionInfo? get connectionInfo => null;

  @override
  int get contentLength => _imageData.length;

  @override
  List<io.Cookie> get cookies => [];

  @override
  Future<io.Socket> detachSocket() async {
    throw UnsupportedError('Mock response does not support detachSocket');
  }

  @override
  io.HttpHeaders get headers => TestHttpHeaders();

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => false;

  @override
  String get reasonPhrase => 'OK';

  @override
  Future<io.HttpClientResponse> redirect([
    String? method,
    Uri? url,
    bool? followLoops,
  ]) async {
    return this;
  }

  @override
  List<io.RedirectInfo> get redirects => [];

  @override
  int get statusCode => 200;

  @override
  Stream<List<int>> timeout(
    Duration timeLimit, {
    void Function(EventSink<List<int>> sink)? onTimeout,
  }) {
    return Stream<List<int>>.fromIterable([
      _imageData,
    ]).timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Future<bool> any(bool Function(List<int> element) test) {
    return Stream<List<int>>.fromIterable([_imageData]).any(test);
  }

  @override
  Stream<List<int>> asBroadcastStream({
    void Function(StreamSubscription<List<int>> subscription)? onListen,
    void Function(StreamSubscription<List<int>> subscription)? onCancel,
  }) {
    return Stream<List<int>>.fromIterable([
      _imageData,
    ]).asBroadcastStream(onListen: onListen, onCancel: onCancel);
  }

  @override
  Stream<E> asyncExpand<E>(Stream<E>? Function(List<int> event) convert) {
    return Stream<List<int>>.fromIterable([_imageData]).asyncExpand(convert);
  }

  @override
  Stream<E> asyncMap<E>(FutureOr<E> Function(List<int> event) convert) {
    return Stream<List<int>>.fromIterable([_imageData]).asyncMap(convert);
  }

  @override
  Stream<R> cast<R>() {
    return Stream<List<int>>.fromIterable([_imageData]).cast<R>();
  }

  @override
  Future<bool> contains(Object? needle) {
    return Stream<List<int>>.fromIterable([_imageData]).contains(needle);
  }

  @override
  Stream<List<int>> distinct([
    bool Function(List<int> previous, List<int> next)? equals,
  ]) {
    return Stream<List<int>>.fromIterable([_imageData]).distinct(equals);
  }

  @override
  Future<E> drain<E>([E? futureValue]) {
    return Stream<List<int>>.fromIterable([_imageData]).drain(futureValue);
  }

  @override
  Future<List<int>> elementAt(int index) {
    return Stream<List<int>>.fromIterable([_imageData]).elementAt(index);
  }

  @override
  Future<bool> every(bool Function(List<int> element) test) {
    return Stream<List<int>>.fromIterable([_imageData]).every(test);
  }

  @override
  Stream<S> expand<S>(Iterable<S> Function(List<int> element) convert) {
    return Stream<List<int>>.fromIterable([_imageData]).expand(convert);
  }

  @override
  Future<List<int>> get first =>
      Stream<List<int>>.fromIterable([_imageData]).first;

  @override
  Future<List<int>> firstWhere(
    bool Function(List<int> element) test, {
    List<int> Function()? orElse,
  }) {
    return Stream<List<int>>.fromIterable([
      _imageData,
    ]).firstWhere(test, orElse: orElse);
  }

  @override
  Future<S> fold<S>(
    S initialValue,
    S Function(S previous, List<int> element) combine,
  ) {
    return Stream<List<int>>.fromIterable([
      _imageData,
    ]).fold(initialValue, combine);
  }

  @override
  Future<void> forEach(void Function(List<int> element) action) {
    return Stream<List<int>>.fromIterable([_imageData]).forEach(action);
  }

  @override
  Stream<List<int>> handleError(
    Function onError, {
    bool Function(Object?)? test,
  }) {
    return Stream<List<int>>.fromIterable([
      _imageData,
    ]).handleError(onError, test: test);
  }

  @override
  bool get isBroadcast => false;

  @override
  Future<bool> get isEmpty => Future.value(false);

  @override
  Future<String> join([String separator = '']) {
    return Stream<List<int>>.fromIterable([_imageData]).join(separator);
  }

  @override
  Future<List<int>> get last =>
      Stream<List<int>>.fromIterable([_imageData]).last;

  @override
  Future<List<int>> lastWhere(
    bool Function(List<int> element) test, {
    List<int> Function()? orElse,
  }) {
    return Stream<List<int>>.fromIterable([
      _imageData,
    ]).lastWhere(test, orElse: orElse);
  }

  @override
  Future<int> get length => Stream<List<int>>.fromIterable([_imageData]).length;

  @override
  Stream<S> map<S>(S Function(List<int> event) convert) {
    return Stream<List<int>>.fromIterable([_imageData]).map(convert);
  }

  @override
  Future<dynamic> pipe(StreamConsumer<List<int>> streamConsumer) {
    return Stream<List<int>>.fromIterable([_imageData]).pipe(streamConsumer);
  }

  @override
  Future<List<int>> reduce(
    List<int> Function(List<int> previous, List<int> element) combine,
  ) {
    return Stream<List<int>>.fromIterable([_imageData]).reduce(combine);
  }

  @override
  Future<List<int>> get single =>
      Stream<List<int>>.fromIterable([_imageData]).single;

  @override
  Future<List<int>> singleWhere(
    bool Function(List<int> element) test, {
    List<int> Function()? orElse,
  }) {
    return Stream<List<int>>.fromIterable([
      _imageData,
    ]).singleWhere(test, orElse: orElse);
  }

  @override
  Stream<List<int>> skip(int count) {
    return Stream<List<int>>.fromIterable([_imageData]).skip(count);
  }

  @override
  Stream<List<int>> skipWhile(bool Function(List<int> element) test) {
    return Stream<List<int>>.fromIterable([_imageData]).skipWhile(test);
  }

  @override
  Stream<List<int>> take(int count) {
    return Stream<List<int>>.fromIterable([_imageData]).take(count);
  }

  @override
  Stream<List<int>> takeWhile(bool Function(List<int> element) test) {
    return Stream<List<int>>.fromIterable([_imageData]).takeWhile(test);
  }

  @override
  Future<List<List<int>>> toList() {
    return Stream<List<int>>.fromIterable([_imageData]).toList();
  }

  @override
  Future<Set<List<int>>> toSet() {
    return Stream<List<int>>.fromIterable([_imageData]).toSet();
  }

  @override
  Stream<S> transform<S>(StreamTransformer<List<int>, S> streamTransformer) {
    return Stream<List<int>>.fromIterable([
      _imageData,
    ]).transform(streamTransformer);
  }

  @override
  Stream<List<int>> where(bool Function(List<int> event) test) {
    return Stream<List<int>>.fromIterable([_imageData]).where(test);
  }

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_imageData]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class TestHttpOverrides extends io.HttpOverrides {
  @override
  io.HttpClient createHttpClient(io.SecurityContext? context) {
    return TestHttpClient();
  }
}
