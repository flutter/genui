class GCliProcess {
  GCliProcess();

  Future<void> run() async {
    // Simulate some processing time
    await Future.delayed(const Duration(seconds: 2));
  }
}
