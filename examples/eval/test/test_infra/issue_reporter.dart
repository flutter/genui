import 'package:flutter_test/flutter_test.dart';

/// A class that collects issues found during testing.
///
/// Instead of failing the test immediately, it prints the issues
/// and fails the test execution at the end.
class IssueReporter {
  IssueReporter();

  int _issuesFound = 0;

  void expect(bool expectation, String issue) {
    if (expectation) return;
    // ignore: avoid_print
    print('Issue: $issue');
    _issuesFound++;
  }

  void failIfIssuesFound() {
    if (_issuesFound > 0) {
      fail('Found $_issuesFound issues');
    }
  }
}
