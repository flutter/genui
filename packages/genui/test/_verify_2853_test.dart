import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  late DataContext ctx;
  late InMemoryDataModel model;

  setUp(() {
    model = InMemoryDataModel();
    ctx = DataContext(model, DataPath.root,
        functions: BasicCatalogItems.asCatalog().functions);
  });

  test('la repro exacta del issue #2853', () async {
    model.update(DataPath('/email'), '');
    final checks = <JsonMap>[
      {
        'condition': {
          'call': 'required',
          'args': {
            'value': {'path': '/email'},
          },
        },
        'message': 'Required.',
      },
    ];
    final direct =
        await ctx.evaluateConditionStream(checks.first['condition']).first;
    final viaHelper =
        await ctx.evaluateConditionStream(checksToExpression(checks)).first;
    // ignore: avoid_print
    print('REPRO condición suelta: $direct  |  por checksToExpression: $viaHelper');
    expect(direct, isFalse);
    expect(viaHelper, isFalse, reason: 'este era el bug');
  });

  test('los tres casos de la tabla del issue', () async {
    model.update(DataPath('/no'), false);
    Future<bool> ev(Object? e) => ctx.evaluateConditionStream(e).first;
    final req = {
      'call': 'required',
      'args': {
        'value': {'path': '/email'},
      },
    };
    model.update(DataPath('/email'), '');
    final rows = <String, bool>{
      'and[ literal false ]': await ev({'call': 'and', 'args': {'values': [false]}}),
      'and[ path a false ]':
          await ev({'call': 'and', 'args': {'values': [{'path': '/no'}]}}),
      'and[ required anidado ]':
          await ev({'call': 'and', 'args': {'values': [req]}}),
      'functionCall envuelto':
          await ev({'functionCall': {'call': 'and', 'args': {'values': [false]}}}),
      'función inexistente envuelta': await ev(
          {'functionCall': {'call': 'noSuchFunction', 'args': <String, Object?>{}}}),
    };
    rows.forEach((k, v) {
      // ignore: avoid_print
      print('TABLA ${k.padRight(30)} -> $v');
    });
  });

  test('el email de #2854 sigue roto o no', () async {
    model.update(DataPath('/e'), 'diego@example.com');
    final v = await ctx.evaluateConditionStream({
      'call': 'email',
      'args': {
        'value': {'path': '/e'},
      },
    }).first;
    // ignore: avoid_print
    print('EMAIL diego@example.com -> $v');
  });
}
