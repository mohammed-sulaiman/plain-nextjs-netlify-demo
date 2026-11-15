import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repository.dart';
import '../data/supabase_repository.dart';
import '../models/models.dart';
import '../services/cloud.dart';
import 'tree_store.dart';

/// Login state. Signed out → the tree lives on the device; signed in → the
/// tree lives in Supabase and is available on every device.
class AccountController extends ChangeNotifier {
  final TreeStore store;
  StreamSubscription<AuthState>? _sub;
  bool _cloudActive = false;

  AccountController(this.store);

  bool get available => CloudConfig.isConfigured;
  User? get user => CloudConfig.client?.auth.currentUser;
  bool get signedIn => user != null;

  /// Picks the right repository at startup and follows auth changes
  /// (including OAuth redirects).
  Future<void> init() async {
    final client = CloudConfig.client;
    if (client == null) {
      await store.load();
      return;
    }
    if (client.auth.currentUser != null) {
      await _useCloud();
    } else {
      await store.load();
    }
    _sub = client.auth.onAuthStateChange.listen((s) async {
      if (s.event == AuthChangeEvent.signedIn && !_cloudActive) {
        await _useCloud();
      } else if (s.event == AuthChangeEvent.signedOut && _cloudActive) {
        _cloudActive = false;
        await store.switchRepository(LocalTreeRepository());
      }
      notifyListeners();
    });
  }

  Future<void> _useCloud() async {
    _cloudActive = true;
    await store.switchRepository(SupabaseTreeRepository(CloudConfig.client!));
    notifyListeners();
  }

  /// Returns the on-device tree, so the UI can offer to upload it when the
  /// cloud tree is still empty.
  Future<FamilyData> localTree() => LocalTreeRepository().load();

  Future<void> signIn(String email, String password) async {
    await CloudConfig.client!.auth
        .signInWithPassword(email: email, password: password);
    if (!_cloudActive) await _useCloud();
  }

  /// Returns true if the user is signed in immediately (no email
  /// confirmation required by the project settings).
  Future<bool> signUp(String email, String password) async {
    final res = await CloudConfig.client!.auth
        .signUp(email: email, password: password);
    if (res.session != null && !_cloudActive) await _useCloud();
    return res.session != null;
  }

  /// Deep link that brings mobile/desktop users back after OAuth. It must be
  /// listed in Supabase → Authentication → URL Configuration → Redirect URLs.
  static const oauthRedirect = 'com.familytree.family_tree://login-callback';

  Future<void> signInWithGoogle() => CloudConfig.client!.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : oauthRedirect,
      );

  Future<void> resetPassword(String email) =>
      CloudConfig.client!.auth.resetPasswordForEmail(email);

  Future<void> signOut() async {
    await CloudConfig.client!.auth.signOut();
    if (_cloudActive) {
      _cloudActive = false;
      await store.switchRepository(LocalTreeRepository());
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
