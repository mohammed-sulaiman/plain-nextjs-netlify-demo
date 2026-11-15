import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/supabase_repository.dart';
import '../models/models.dart';

/// Supabase configuration is injected at build time so no secrets live in
/// the repository:
///
///   flutter run --dart-define=SUPABASE_URL=https://xyz.supabase.co \
///               --dart-define=SUPABASE_ANON_KEY=eyJ...
class CloudConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  static Future<void> init() async {
    if (!isConfigured) return;
    await Supabase.initialize(url: url, publishableKey: anonKey);
  }

  static SupabaseClient? get client =>
      isConfigured ? Supabase.instance.client : null;
}

/// Resolves [Person.photo] references to something displayable.
class PhotoResolver {
  static final _signed = <String, String>{};

  /// Returns either raw bytes (data URIs) or a URL.
  static Future<Object?> resolve(String? ref) async {
    if (ref == null || ref.isEmpty) return null;
    if (ref.startsWith('data:')) return UriData.parse(ref).contentAsBytes();
    if (ref.startsWith('http')) return ref;
    if (ref.startsWith('storage:')) {
      final path = ref.substring('storage:'.length);
      final cached = _signed[path];
      if (cached != null) return cached;
      final client = CloudConfig.client;
      if (client == null) return null;
      final url = await client.storage
          .from(SupabaseTreeRepository.photoBucket)
          .createSignedUrl(path, 60 * 60 * 24);
      _signed[path] = url;
      return url;
    }
    return null;
  }

  static Future<Uint8List?> bytes(String? ref) async {
    final r = await resolve(ref);
    if (r is Uint8List) return r;
    if (r is String) {
      final res = await http.get(Uri.parse(r));
      if (res.statusCode == 200) return res.bodyBytes;
    }
    return null;
  }
}

class FaceComparison {
  final String personId;
  final double similarity; // 0–100
  const FaceComparison(this.personId, this.similarity);
}

class FaceSimilarityException implements Exception {
  final String code; // not_configured, not_signed_in, no_consent, no_face, failed
  final String? detail;
  const FaceSimilarityException(this.code, [this.detail]);
  @override
  String toString() => 'FaceSimilarityException($code, $detail)';
}

/// Face similarity is computed by the `face-similarity` Supabase Edge
/// Function (see supabase/functions/face-similarity), which calls a face
/// comparison API server-side. Keys never reach the client, the user must be
/// signed in, and only persons with explicit consent are compared.
class FaceSimilarityService {
  Future<double> compare(Person a, Person b) async {
    final res = await compareMany(a, [b]);
    if (res.isEmpty) throw const FaceSimilarityException('no_face');
    return res.first.similarity;
  }

  Future<List<FaceComparison>> compareMany(
      Person source, List<Person> targets) async {
    final client = CloudConfig.client;
    if (client == null) throw const FaceSimilarityException('not_configured');
    if (client.auth.currentUser == null) {
      throw const FaceSimilarityException('not_signed_in');
    }
    final eligible = targets.where((t) => t.faceConsent && t.photo != null);
    if (!source.faceConsent || source.photo == null) {
      throw const FaceSimilarityException('no_consent');
    }
    final sourceBytes = await PhotoResolver.bytes(source.photo);
    if (sourceBytes == null) throw const FaceSimilarityException('no_face');

    final targetPayload = <Map<String, String>>[];
    for (final t in eligible) {
      final bytes = await PhotoResolver.bytes(t.photo);
      if (bytes != null) {
        targetPayload.add({'id': t.id, 'image': base64Encode(bytes)});
      }
    }
    if (targetPayload.isEmpty) return [];

    try {
      final res = await client.functions.invoke('face-similarity', body: {
        'source': base64Encode(sourceBytes),
        'targets': targetPayload,
      });
      final data = res.data as Map<String, dynamic>;
      if (data['error'] != null) {
        throw FaceSimilarityException(
            data['error'] == 'no_face' ? 'no_face' : 'failed',
            data['error'] as String?);
      }
      final list = (data['results'] as List)
          .map((e) => FaceComparison(
              e['id'] as String, (e['similarity'] as num).toDouble()))
          .toList()
        ..sort((a, b) => b.similarity.compareTo(a.similarity));
      return list;
    } on FunctionException catch (e) {
      throw FaceSimilarityException('failed', e.details?.toString());
    }
  }
}
