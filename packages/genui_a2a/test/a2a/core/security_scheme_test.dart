// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:genui_a2a/src/a2a/a2a.dart';

void main() {
  group('SecurityScheme', () {
    test('APIKeySecurityScheme fromJson and toJson', () {
      final json = {
        'type': 'apiKey',
        'name': 'X-API-Key',
        'in': 'header',
        'description': 'API Key auth',
      };
      final scheme = SecurityScheme.fromJson(json) as APIKeySecurityScheme;
      expect(scheme.name, 'X-API-Key');
      expect(scheme.in_, 'header');
      expect(scheme.toJson(), json);
    });

    test('APIKeySecurityScheme copyWith', () {
      const scheme = APIKeySecurityScheme(name: 'key', in_: 'header');
      final APIKeySecurityScheme copy = scheme.copyWith(name: 'new-key');
      expect(copy.name, 'new-key');
    });

    test('APIKeySecurityScheme toString', () {
      const scheme = APIKeySecurityScheme(name: 'key', in_: 'header');
      expect(scheme.toString(), contains('APIKeySecurityScheme'));
    });

    test('HttpAuthSecurityScheme fromJson and toJson', () {
      final json = {
        'type': 'http',
        'scheme': 'bearer',
        'bearerFormat': 'JWT',
        'description': 'JWT auth',
      };
      final scheme = SecurityScheme.fromJson(json) as HttpAuthSecurityScheme;
      expect(scheme.scheme, 'bearer');
      expect(scheme.bearerFormat, 'JWT');
      expect(scheme.toJson(), json);
    });

    test('HttpAuthSecurityScheme copyWith', () {
      const scheme = HttpAuthSecurityScheme(scheme: 'bearer');
      final HttpAuthSecurityScheme copy = scheme.copyWith(bearerFormat: 'JWT');
      expect(copy.bearerFormat, 'JWT');
    });

    test('HttpAuthSecurityScheme toString', () {
      const scheme = HttpAuthSecurityScheme(scheme: 'bearer');
      expect(scheme.toString(), contains('HttpAuthSecurityScheme'));
    });

    test('OAuth2SecurityScheme fromJson and toJson', () {
      final Map<String, Object> json = {
        'type': 'oauth2',
        'description': 'OAuth2 auth',
        'flows': {
          'implicit': {
            'authorizationUrl': 'https://example.com/auth',
            'scopes': {'read': 'Read access'},
            'tokenUrl': null,
            'refreshUrl': null,
          },
          'password': null,
          'clientCredentials': null,
          'authorizationCode': null,
        },
      };
      final scheme = SecurityScheme.fromJson(json) as OAuth2SecurityScheme;
      expect(
        scheme.flows.implicit!.authorizationUrl,
        'https://example.com/auth',
      );
      expect(scheme.toJson(), json);
    });

    test('OAuth2SecurityScheme copyWith', () {
      const flows = OAuthFlows();
      const scheme = OAuth2SecurityScheme(flows: flows);
      final OAuth2SecurityScheme copy = scheme.copyWith(
        description: 'New description',
      );
      expect(copy.description, 'New description');
    });

    test('OAuth2SecurityScheme toString', () {
      const flows = OAuthFlows();
      const scheme = OAuth2SecurityScheme(flows: flows);
      expect(scheme.toString(), contains('OAuth2SecurityScheme'));
    });

    test('OpenIdConnectSecurityScheme fromJson and toJson', () {
      final json = {
        'type': 'openIdConnect',
        'description': 'OIDC auth',
        'openIdConnectUrl':
            'https://example.com/.well-known/openid-configuration',
      };
      final scheme =
          SecurityScheme.fromJson(json) as OpenIdConnectSecurityScheme;
      expect(
        scheme.openIdConnectUrl,
        'https://example.com/.well-known/openid-configuration',
      );
      expect(scheme.toJson(), json);
    });

    test('OpenIdConnectSecurityScheme copyWith', () {
      const scheme = OpenIdConnectSecurityScheme(openIdConnectUrl: 'url');
      final OpenIdConnectSecurityScheme copy = scheme.copyWith(
        openIdConnectUrl: 'new-url',
      );
      expect(copy.openIdConnectUrl, 'new-url');
    });

    test('OpenIdConnectSecurityScheme toString', () {
      const scheme = OpenIdConnectSecurityScheme(openIdConnectUrl: 'url');
      expect(scheme.toString(), contains('OpenIdConnectSecurityScheme'));
    });

    test('MutualTlsSecurityScheme fromJson and toJson', () {
      final json = {'type': 'mutualTls', 'description': 'mTLS auth'};
      final scheme = SecurityScheme.fromJson(json) as MutualTlsSecurityScheme;
      expect(scheme.type, 'mutualTls');
      expect(scheme.toJson(), json);
    });

    test('MutualTlsSecurityScheme copyWith', () {
      const scheme = MutualTlsSecurityScheme();
      final MutualTlsSecurityScheme copy = scheme.copyWith(
        description: 'New description',
      );
      expect(copy.description, 'New description');
    });

    test('MutualTlsSecurityScheme toString', () {
      const scheme = MutualTlsSecurityScheme();
      expect(scheme.toString(), contains('MutualTlsSecurityScheme'));
    });

    test('OAuthFlows and OAuthFlow copyWith and toString', () {
      const flow = OAuthFlow(scopes: {'read': 'read'});
      const flows = OAuthFlows(implicit: flow);

      final OAuthFlow flowCopy = flow.copyWith(
        refreshUrl: 'https://example.com/refresh',
      );
      expect(flowCopy.refreshUrl, 'https://example.com/refresh');

      final OAuthFlows flowsCopy = flows.copyWith(password: flow);
      expect(flowsCopy.password, flow);

      expect(flow.toString(), contains('OAuthFlow'));
      expect(flows.toString(), contains('OAuthFlows'));
    });

    test('SecurityScheme.fromJson throws on unknown type', () {
      final json = {'type': 'unknown'};
      expect(() => SecurityScheme.fromJson(json), throwsArgumentError);
    });
    test('APIKeySecurityScheme operator == and hashCode', () {
      const scheme1 = APIKeySecurityScheme(name: 'key', in_: 'header');
      const scheme2 = APIKeySecurityScheme(name: 'key', in_: 'header');
      expect(scheme1, equals(scheme2));
      expect(scheme1.hashCode, equals(scheme2.hashCode));
    });

    test('HttpAuthSecurityScheme operator == and hashCode', () {
      const scheme1 = HttpAuthSecurityScheme(scheme: 'bearer');
      const scheme2 = HttpAuthSecurityScheme(scheme: 'bearer');
      expect(scheme1, equals(scheme2));
      expect(scheme1.hashCode, equals(scheme2.hashCode));
    });

    test('OAuth2SecurityScheme operator == and hashCode', () {
      const flows = OAuthFlows();
      const scheme1 = OAuth2SecurityScheme(flows: flows);
      const scheme2 = OAuth2SecurityScheme(flows: flows);
      expect(scheme1, equals(scheme2));
      expect(scheme1.hashCode, equals(scheme2.hashCode));
    });

    test('OpenIdConnectSecurityScheme operator == and hashCode', () {
      const scheme1 = OpenIdConnectSecurityScheme(openIdConnectUrl: 'url');
      const scheme2 = OpenIdConnectSecurityScheme(openIdConnectUrl: 'url');
      expect(scheme1, equals(scheme2));
      expect(scheme1.hashCode, equals(scheme2.hashCode));
    });

    test('MutualTlsSecurityScheme operator == and hashCode', () {
      const scheme1 = MutualTlsSecurityScheme();
      const scheme2 = MutualTlsSecurityScheme();
      expect(scheme1, equals(scheme2));
      expect(scheme1.hashCode, equals(scheme2.hashCode));
    });

    test('OAuthFlows operator == and hashCode', () {
      const flows1 = OAuthFlows();
      const flows2 = OAuthFlows();
      expect(flows1, equals(flows2));
      expect(flows1.hashCode, equals(flows2.hashCode));
    });

    test('OAuthFlow operator == and hashCode', () {
      const flow1 = OAuthFlow(scopes: {'read': 'read'});
      const flow2 = OAuthFlow(scopes: {'read': 'read'});
      expect(flow1, equals(flow2));
      expect(flow1.hashCode, equals(flow2.hashCode));
    });
    test('APIKeySecurityScheme copyWith without arguments works', () {
      const scheme = APIKeySecurityScheme(name: 'key', in_: 'header');
      final APIKeySecurityScheme copy = scheme.copyWith();
      expect(copy.name, 'key');
    });

    test('HttpAuthSecurityScheme copyWith without arguments works', () {
      const scheme = HttpAuthSecurityScheme(scheme: 'bearer');
      final HttpAuthSecurityScheme copy = scheme.copyWith();
      expect(copy.scheme, 'bearer');
    });

    test('OAuth2SecurityScheme copyWith without arguments works', () {
      const flows = OAuthFlows();
      const scheme = OAuth2SecurityScheme(flows: flows);
      final OAuth2SecurityScheme copy = scheme.copyWith();
      expect(copy.flows, equals(flows));
    });

    test('OpenIdConnectSecurityScheme copyWith without arguments works', () {
      const scheme = OpenIdConnectSecurityScheme(openIdConnectUrl: 'url');
      final OpenIdConnectSecurityScheme copy = scheme.copyWith();
      expect(copy.openIdConnectUrl, 'url');
    });

    test('MutualTlsSecurityScheme copyWith without arguments works', () {
      const scheme = MutualTlsSecurityScheme();
      final MutualTlsSecurityScheme copy = scheme.copyWith();
      expect(copy.type, 'mutualTls');
    });

    test('OAuthFlow copyWith without arguments works', () {
      const flow = OAuthFlow(scopes: {'read': 'read'});
      final OAuthFlow copy = flow.copyWith();
      expect(copy.scopes, equals({'read': 'read'}));
    });

    test('OAuthFlows copyWith without arguments works', () {
      const flows = OAuthFlows();
      final OAuthFlows copy = flows.copyWith();
      expect(copy, equals(flows));
    });
  });
}
