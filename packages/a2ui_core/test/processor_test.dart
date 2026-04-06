import 'package:a2ui_core/src/processing/processor.dart';
import 'package:a2ui_core/src/protocol/catalog.dart';
import 'package:a2ui_core/src/protocol/messages.dart';
import 'package:a2ui_core/src/protocol/minimal_catalog.dart';
import 'package:a2ui_core/src/state/component_model.dart';
import 'package:a2ui_core/src/state/surface_model.dart';
import 'package:test/test.dart';

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
        CreateSurfaceMessage(surfaceId: 's1', catalogId: catalog.id),
      ]);

      final SurfaceModel<ComponentApi>? surface = processor.groupModel
          .getSurface('s1');
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
            {'id': 'root', 'component': 'Text', 'text': 'Hello'},
          ],
        ),
      ]);

      final SurfaceModel<ComponentApi>? surface = processor.groupModel
          .getSurface('s1');
      final ComponentModel? root = surface?.componentsModel.get('root');
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

      final SurfaceModel<ComponentApi>? surface = processor.groupModel
          .getSurface('s1');
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
      final Map<String, dynamic> caps = processor.getClientCapabilities(
        includeInlineCatalogs: true,
      );
      final v09 = caps['v0.9'] as Map<String, dynamic>;
      expect(v09['supportedCatalogIds'], contains(catalog.id));

      final inline = v09['inlineCatalogs'] as List;
      final first = inline.first as Map<String, dynamic>;
      expect(first['catalogId'], catalog.id);
      expect(first['components'], contains('Text'));
    });

    test('aggregates client data model', () {
      processor.processMessages([
        CreateSurfaceMessage(
          surfaceId: 's1',
          catalogId: catalog.id,
          sendDataModel: true,
        ),
        UpdateDataModelMessage(surfaceId: 's1', path: '/foo', value: 'bar'),
        CreateSurfaceMessage(
          surfaceId: 's2',
          catalogId: catalog.id,
          sendDataModel: false,
        ),
        UpdateDataModelMessage(surfaceId: 's2', path: '/secret', value: 'baz'),
      ]);

      final Map<String, dynamic>? dataModel = processor.getClientDataModel();
      expect(dataModel, isNotNull);
      final surfaces =
          dataModel?['surfaces'] as Map<String, dynamic>?;
      expect(surfaces, contains('s1'));
      expect(surfaces, isNot(contains('s2')));
      expect(surfaces?['s1'], {'foo': 'bar'});
    });
  });
}
