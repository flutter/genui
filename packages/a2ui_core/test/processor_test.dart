import 'package:test/test.dart';
import 'package:a2ui_core/src/processing/processor.dart';
import 'package:a2ui_core/src/protocol/catalog.dart';
import 'package:a2ui_core/src/protocol/messages.dart';
import 'package:a2ui_core/src/protocol/minimal_catalog.dart';
import 'package:a2ui_core/src/state/surface_model.dart';

void main() {
  group('MessageProcessor', () {
    late MinimalCatalog catalog;
    late MessageProcessor processor;

    setUp(() {
      catalog = MinimalCatalog();
      processor = MessageProcessor(catalogs: [catalog]);
    });

    test('creates surface', () {
      processor.processMessages([
        CreateSurfaceMessage(
          surfaceId: 's1',
          catalogId: catalog.id,
        ),
      ]);

      final surface = processor.groupModel.getSurface('s1');
      expect(surface, isNotNull);
      expect(surface?.id, 's1');
      expect(surface?.catalog.id, catalog.id);
    });

    test('updates components', () {
      processor.processMessages([
        CreateSurfaceMessage(surfaceId: 's1', catalogId: catalog.id),
        UpdateComponentsMessage(
          surfaceId: 's1',
          components: [
            {'id': 'root', 'component': 'Text', 'text': 'Hello'}
          ],
        ),
      ]);

      final surface = processor.groupModel.getSurface('s1');
      final root = surface?.componentsModel.get('root');
      expect(root, isNotNull);
      expect(root?.type, 'Text');
      expect(root?.properties['text'], 'Hello');
    });

    test('updates data model', () {
      processor.processMessages([
        CreateSurfaceMessage(surfaceId: 's1', catalogId: catalog.id),
        UpdateDataModelMessage(
          surfaceId: 's1',
          path: '/user/name',
          value: 'Alice',
        ),
      ]);

      final surface = processor.groupModel.getSurface('s1');
      expect(surface?.dataModel.get('/user/name'), 'Alice');
    });

    test('deletes surface', () {
      processor.processMessages([
        CreateSurfaceMessage(surfaceId: 's1', catalogId: catalog.id),
        DeleteSurfaceMessage(surfaceId: 's1'),
      ]);

      expect(processor.groupModel.getSurface('s1'), isNull);
    });

    test('generates client capabilities with inline catalogs', () {
      final caps = processor.getClientCapabilities(includeInlineCatalogs: true);
      expect(caps['v0.9']['supportedCatalogIds'], contains(catalog.id));
      
      final inline = caps['v0.9']['inlineCatalogs'] as List;
      expect(inline.first['catalogId'], catalog.id);
      expect(inline.first['components'], contains('Text'));
    });

    test('aggregates client data model', () {
      processor.processMessages([
        CreateSurfaceMessage(surfaceId: 's1', catalogId: catalog.id, sendDataModel: true),
        UpdateDataModelMessage(surfaceId: 's1', path: '/foo', value: 'bar'),
        CreateSurfaceMessage(surfaceId: 's2', catalogId: catalog.id, sendDataModel: false),
        UpdateDataModelMessage(surfaceId: 's2', path: '/secret', value: 'baz'),
      ]);

      final dataModel = processor.getClientDataModel();
      expect(dataModel, isNotNull);
      expect(dataModel?['surfaces'], contains('s1'));
      expect(dataModel?['surfaces'], isNot(contains('s2')));
      expect(dataModel?['surfaces']['s1'], {'foo': 'bar'});
    });
  });
}
