import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_genui/src/core/ui_tools.dart';
import 'package:flutter_genui/src/model/tools.dart';
import 'package:flutter_test/flutter_test.dart';

class _ToolsTest {
  final manager = GenUiManager(catalog: coreCatalog);

  /// Returns a list of [AiTool]s that can be used to manipulate the UI.
  ///
  /// These tools should be provided to the [AiClient] to allow the AI to
  /// generate and modify the UI.
  List<AiTool> getTools() {
    return [AddOrUpdateSurfaceTool(manager), DeleteSurfaceTool(manager)];
  }
}

void main() {
  test('getTools returns the correct tools', () {
    final tools = _ToolsTest().getTools();
    expect(tools, hasLength(2));
    expect(tools[0], isA<AddOrUpdateSurfaceTool>());
    expect(tools[1], isA<DeleteSurfaceTool>());
  });
}
