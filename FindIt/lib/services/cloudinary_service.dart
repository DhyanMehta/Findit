import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class CloudinaryService {
  CloudinaryService._internal();
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;

  // TODO: Put your actual Cloudinary credentials here
  // Get these from your Cloudinary Dashboard -> Settings -> Access Keys
  static const String cloudName = 'dg1qs96lf';
  static const String apiKey =
      '929897679746585'; // Replace with your actual API key
  static const String apiSecret =
      '7pBjacBYAUZBrMANYr7Kf'; // Replace with your actual API secret

  // Alternative: Use unsigned upload preset (make sure it's set to "unsigned" in Cloudinary)
  static const String unsignedUploadPreset = 'findit';

  Future<String> uploadImage(File file) async {
    try {
      // Try unsigned upload first (if preset is configured as unsigned)
      try {
        return await _uploadUnsigned(file);
      } catch (e) {
        print('Unsigned upload failed: $e');
        // Fall back to signed upload
        return await _uploadSigned(file);
      }
    } catch (e) {
      print('All upload methods failed: $e');
      rethrow;
    }
  }

  Future<String> _uploadUnsigned(File file) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = unsignedUploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    print(
      'Uploading to Cloudinary with unsigned preset: $unsignedUploadPreset',
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    print('Cloudinary response status: ${response.statusCode}');
    print('Cloudinary response body: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final secureUrl = data['secure_url'] as String?;
      if (secureUrl == null || secureUrl.isEmpty) {
        throw Exception('Cloudinary response missing secure_url');
      }
      return secureUrl;
    }
    throw Exception(
      'Cloudinary unsigned upload failed: ${response.statusCode} ${response.body}',
    );
  }

  Future<String> _uploadSigned(File file) async {
    if (apiKey == 'YOUR_API_KEY' || apiSecret == 'YOUR_API_SECRET') {
      throw Exception(
        'Please configure your Cloudinary API key and secret in cloudinary_service.dart',
      );
    }

    final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round();
    final signature = _generateSignature(timestamp);

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['api_key'] = apiKey
      ..fields['timestamp'] = timestamp.toString()
      ..fields['signature'] = signature
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    print('Uploading to Cloudinary with signed upload');

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    print('Cloudinary signed response status: ${response.statusCode}');
    print('Cloudinary signed response body: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final secureUrl = data['secure_url'] as String?;
      if (secureUrl == null || secureUrl.isEmpty) {
        throw Exception('Cloudinary response missing secure_url');
      }
      return secureUrl;
    }
    throw Exception(
      'Cloudinary signed upload failed: ${response.statusCode} ${response.body}',
    );
  }

  String _generateSignature(int timestamp) {
    // Generate signature for signed uploads
    final params = {'timestamp': timestamp.toString()};

    // Sort parameters alphabetically
    final sortedParams = params.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Create query string
    final queryString = sortedParams
        .map((e) => '${e.key}=${e.value}')
        .join('&');

    // Append API secret
    final stringToSign = queryString + apiSecret;

    // Generate SHA1 hash
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);

    return digest.toString();
  }
}
