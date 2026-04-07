import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EpicAuthService {
  static const String _tokenEndpoint =
      'https://account-public-service-prod.ol.epicgames.com/account/api/oauth/token';
  static const String _clientId = '34a02cf8f4414e29b15921876da36f9a';
  static const String _clientSecret = 'daafbccc737745039dffe53d94fc76cf';

  String? _accessToken;
  String? _refreshToken;
  String? _accountId;

  String? get accessToken => _accessToken;
  String? get accountId => _accountId;
  bool get isAuthenticated => _accessToken != null;

  Future<void> loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('epic_access_token');
    _refreshToken = prefs.getString('epic_refresh_token');
    _accountId = prefs.getString('epic_account_id');
  }

  Future<void> _saveTokens() async {
    final prefs = await SharedPreferences.getInstance();
    if (_accessToken != null) {
      await prefs.setString('epic_access_token', _accessToken!);
    } else {
      await prefs.remove('epic_access_token');
    }

    if (_refreshToken != null) {
      await prefs.setString('epic_refresh_token', _refreshToken!);
    } else {
      await prefs.remove('epic_refresh_token');
    }

    if (_accountId != null) {
      await prefs.setString('epic_account_id', _accountId!);
    } else {
      await prefs.remove('epic_account_id');
    }
  }

  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _accountId = null;
    await _saveTokens();
  }

  Future<bool> exchangeCode(
    String code, {
    bool isAuthorizationCode = false,
  }) async {
    final basicAuth = base64Encode(utf8.encode('$_clientId:$_clientSecret'));

    final body = <String, String>{
      'grant_type': isAuthorizationCode
          ? 'authorization_code'
          : 'exchange_code',
      if (isAuthorizationCode) 'code': code else 'exchange_code': code,
      'token_type': 'eg1',
    };

    final response = await http.post(
      Uri.parse(_tokenEndpoint),
      headers: {
        'Authorization': 'Basic $basicAuth',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _accessToken = data['access_token'];
      _refreshToken = data['refresh_token'];
      _accountId = data['account_id'];
      await _saveTokens();
      return true;
    } else {
      print('Auth failed: ${response.body}');
      return false;
    }
  }

  Future<bool> refreshTokens() async {
    if (_refreshToken == null) return false;

    final basicAuth = base64Encode(utf8.encode('$_clientId:$_clientSecret'));

    final response = await http.post(
      Uri.parse(_tokenEndpoint),
      headers: {
        'Authorization': 'Basic $basicAuth',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': _refreshToken!,
        'token_type': 'eg1',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _accessToken = data['access_token'];
      _refreshToken = data['refresh_token'];
      _accountId = data['account_id'];
      await _saveTokens();
      return true;
    } else {
      // Clear tokens if refresh fails
      await logout();
      return false;
    }
  }
}
