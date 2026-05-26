import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../models/docker_container.dart';
import '../models/docker_image.dart';
import '../models/docker_network.dart';
import '../models/docker_volume.dart';
import '../models/server_usage.dart';
import '../models/container_file.dart';

class DockerService {
  final String baseUrl;
  final String? apiKey;
  final bool ignoreSsl;
  late final http.Client _client;

  DockerService({required this.baseUrl, this.apiKey, this.ignoreSsl = false}) {
    if (ignoreSsl) {
      final ioc = HttpClient();
      ioc.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      _client = IOClient(ioc);
    } else {
      _client = http.Client();
    }
  }

  Future<List<DockerContainer>> getContainers() async {
    // 确保 baseUrl 没有尾随斜杠
    final cleanBaseUrl = baseUrl.endsWith('/') 
        ? baseUrl.substring(0, baseUrl.length - 1) 
        : baseUrl;
        
    final url = Uri.parse('$cleanBaseUrl/containers/summary');

    final headers = <String, String>{};
    if (apiKey != null && apiKey!.isNotEmpty) {
      headers['X-API-Key'] = apiKey!;
    }

    try {
      final response = await _client.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => DockerContainer.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load containers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<DockerImage>> getImages() async {
    // 确保 baseUrl 没有尾随斜杠
    final cleanBaseUrl = baseUrl.endsWith('/') 
        ? baseUrl.substring(0, baseUrl.length - 1) 
        : baseUrl;
        
    final url = Uri.parse('$cleanBaseUrl/images');

    final headers = <String, String>{};
    if (apiKey != null && apiKey!.isNotEmpty) {
      headers['X-API-Key'] = apiKey!;
    }

    try {
      final response = await _client.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => DockerImage.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load images: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<DockerNetwork>> getNetworks() async {
    final cleanBaseUrl = baseUrl.endsWith('/') 
        ? baseUrl.substring(0, baseUrl.length - 1) 
        : baseUrl;
        
    final url = Uri.parse('$cleanBaseUrl/networks');

    final headers = <String, String>{};
    if (apiKey != null && apiKey!.isNotEmpty) {
      headers['X-API-Key'] = apiKey!;
    }

    try {
      final response = await _client.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => DockerNetwork.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load networks: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> getNetwork(String id) async {
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final url = Uri.parse('$cleanBaseUrl/networks/$id');

    final headers = <String, String>{};
    if (apiKey != null && apiKey!.isNotEmpty) {
      headers['X-API-Key'] = apiKey!;
    }

    try {
      final response = await _client.get(url, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load network details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<DockerVolume>> getVolumes() async {
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final url = Uri.parse('$cleanBaseUrl/volumes');

    final headers = <String, String>{};
    if (apiKey != null && apiKey!.isNotEmpty) {
      headers['X-API-Key'] = apiKey!;
    }

    try {
      final response = await _client.get(url, headers: headers);

      if (response.statusCode == 200) {
        final dynamic jsonData = json.decode(response.body);
        List<dynamic> list;
        if (jsonData is Map && jsonData.containsKey('Volumes')) {
           list = jsonData['Volumes'];
        } else if (jsonData is List) {
           list = jsonData;
        } else {
           list = [];
        }
        return list.map((json) => DockerVolume.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load volumes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> getVolume(String name) async {
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final url = Uri.parse('$cleanBaseUrl/volumes/$name');

    final headers = <String, String>{};
    if (apiKey != null && apiKey!.isNotEmpty) {
      headers['X-API-Key'] = apiKey!;
    }

    try {
      final response = await _client.get(url, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load volume details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> deleteVolume(String name) async {
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final url = Uri.parse('$cleanBaseUrl/volumes/$name');

    final headers = <String, String>{};
    if (apiKey != null && apiKey!.isNotEmpty) {
      headers['X-API-Key'] = apiKey!;
    }

    try {
      final response = await _client.delete(url, headers: headers);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      } else {
        // Try to parse error message from body if available
        try {
          final body = json.decode(response.body);
          if (body is Map && body.containsKey('message')) {
             throw Exception(body['message']);
          }
        } catch (_) {}
        throw Exception('Failed to delete volume: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<ServerUsage> getUsage() async {
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final url = Uri.parse('$cleanBaseUrl/usage');

    final headers = <String, String>{};
    if (apiKey != null && apiKey!.isNotEmpty) {
      headers['X-API-Key'] = apiKey!;
    }

    try {
      final response = await _client.get(url, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return ServerUsage.fromJson(jsonData);
      } else {
        throw Exception('Failed to load usage: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> getImage(String id) async {
    final cleanBaseUrl = baseUrl.endsWith('/') 
        ? baseUrl.substring(0, baseUrl.length - 1) 
        : baseUrl;
        
    final url = Uri.parse('$cleanBaseUrl/images/$id');

    final headers = <String, String>{};
    if (apiKey != null && apiKey!.isNotEmpty) {
      headers['X-API-Key'] = apiKey!;
    }

    try {
      final response = await _client.get(url, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load image details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> deleteImage(String id) async {
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse('$cleanBaseUrl/images/$id');

    final headers = <String, String>{};
    if (apiKey != null && apiKey!.isNotEmpty) {
      headers['X-API-Key'] = apiKey!;
    }

    try {
      final response = await _client.delete(url, headers: headers);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        } else if (decoded is List) {
           return {'status': 'success', 'details': decoded};
        }
        return {'status': 'success'};
      } else {
        throw Exception('Failed to delete image: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> pullImage(String name, String tag) async {
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse('$cleanBaseUrl/images/pull');

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (apiKey != null && apiKey!.isNotEmpty) {
      headers['X-API-Key'] = apiKey!;
    }

    final body = json.encode({
      'image': name,
      'tag': tag,
    });

    try {
      final response = await _client.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);
        return jsonMap;
      } else {
        throw Exception('Failed to pull image: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> getContainer(String id) async {
    final cleanBaseUrl = baseUrl.endsWith('/') 
        ? baseUrl.substring(0, baseUrl.length - 1) 
        : baseUrl;
        
    final url = Uri.parse('$cleanBaseUrl/containers/$id');

    final headers = <String, String>{};
    if (apiKey != null && apiKey!.isNotEmpty) {
      headers['X-API-Key'] = apiKey!;
    }

    try {
      final response = await _client.get(url, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load container details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> _performContainerAction(String id, String action) async {
    final cleanBaseUrl = baseUrl.endsWith('/') 
        ? baseUrl.substring(0, baseUrl.length - 1) 
        : baseUrl;
        
    final url = Uri.parse('$cleanBaseUrl/containers/$id/$action');

    final headers = <String, String>{};
    if (apiKey != null && apiKey!.isNotEmpty) {
      headers['X-API-Key'] = apiKey!;
    }

    try {
      final response = await _client.post(url, headers: headers);

      if (response.statusCode != 204 && response.statusCode != 200) {
         throw Exception('Failed to $action container: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  Future<List<ContainerFile>> getContainerFiles(String id, {String path = '/'}) async {
    final cleanBaseUrl = baseUrl.endsWith('/') 
        ? baseUrl.substring(0, baseUrl.length - 1) 
        : baseUrl;
        
    final url = Uri.parse('$cleanBaseUrl/containers/$id/files').replace(queryParameters: {'path': path});

    final headers = <String, String>{};
    if (apiKey != null && apiKey!.isNotEmpty) {
      headers['X-API-Key'] = apiKey!;
    }

    try {
      final response = await _client.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => ContainerFile.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load container files: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<String> getContainerFileContent(String id, String path) async {
    final cleanBaseUrl = baseUrl.endsWith('/') 
        ? baseUrl.substring(0, baseUrl.length - 1) 
        : baseUrl;
        
    final url = Uri.parse('$cleanBaseUrl/containers/$id/files').replace(queryParameters: {'path': path});

    final headers = <String, String>{};
    if (apiKey != null && apiKey!.isNotEmpty) {
      headers['X-API-Key'] = apiKey!;
    }

    try {
      final response = await _client.get(url, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);
        return jsonMap['content']?.toString() ?? '';
      } else {
        throw Exception('Failed to load file content: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Uint8List> downloadContainerFile(String id, String path) async {
    final cleanBaseUrl = baseUrl.endsWith('/') 
        ? baseUrl.substring(0, baseUrl.length - 1) 
        : baseUrl;
        
    final url = Uri.parse('$cleanBaseUrl/containers/$id/download').replace(queryParameters: {'path': path});

    final headers = <String, String>{};
    if (apiKey != null && apiKey!.isNotEmpty) {
      headers['X-API-Key'] = apiKey!;
    }

    try {
      final response = await _client.get(url, headers: headers);

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to download file: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> updateContainerFile(String id, String path, String content) async {
    final cleanBaseUrl = baseUrl.endsWith('/') 
        ? baseUrl.substring(0, baseUrl.length - 1) 
        : baseUrl;
        
    final url = Uri.parse('$cleanBaseUrl/containers/$id/files').replace(queryParameters: {'path': path});

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (apiKey != null && apiKey!.isNotEmpty) {
      headers['X-API-Key'] = apiKey!;
    }

    final body = json.encode({'path':path,'content': content});

    try {
      final response = await _client.put(url, headers: headers, body: body);

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to update file: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> startContainer(String id) => _performContainerAction(id, 'start');
  Future<void> stopContainer(String id) => _performContainerAction(id, 'stop');
  Future<void> killContainer(String id) => _performContainerAction(id, 'kill');
  Future<void> restartContainer(String id) => _performContainerAction(id, 'restart');
  Future<void> pauseContainer(String id) => _performContainerAction(id, 'pause');
  Future<void> resumeContainer(String id) => _performContainerAction(id, 'unpause');
  
  Future<Map<String, dynamic>> runContainer(String command) async {
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse('$cleanBaseUrl/containers/run');

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (apiKey != null && apiKey!.isNotEmpty) {
      headers['X-API-Key'] = apiKey!;
    }

    final body = json.encode({'command': command});

    try {
      final response = await _client.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        // Try to decode error body if possible
        try {
           final errorBody = json.decode(response.body);
           if (errorBody is Map<String, dynamic> && errorBody.containsKey('detail')) {
             throw Exception(errorBody['detail']);
           }
        } catch (_) {}
        throw Exception('Failed to run container: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> removeContainer(String id, {bool force = false}) async {
      final cleanBaseUrl = baseUrl.endsWith('/') 
        ? baseUrl.substring(0, baseUrl.length - 1) 
        : baseUrl;
        
    final url = Uri.parse('$cleanBaseUrl/containers/$id').replace(
      queryParameters: {'force': force.toString()},
    );

    final headers = <String, String>{};
    if (apiKey != null && apiKey!.isNotEmpty) {
      headers['X-API-Key'] = apiKey!;
    }

    try {
      final response = await _client.delete(url, headers: headers);

      if (response.statusCode != 204 && response.statusCode != 200) {
          throw Exception('Failed to remove container: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<String>> getStacks() async {
    final cleanBaseUrl = baseUrl.endsWith('/') 
        ? baseUrl.substring(0, baseUrl.length - 1) 
        : baseUrl;
        
    final url = Uri.parse('$cleanBaseUrl/stacks');

    final headers = <String, String>{};
    if (apiKey != null && apiKey!.isNotEmpty) {
      headers['X-API-Key'] = apiKey!;
    }

    try {
      final response = await _client.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map<String>((item) {
          if (item is String) return item;
          if (item is Map) {
             return (item['Name'] ?? item['name'] ?? '').toString();
          }
          return '';
        }).where((s) => s.isNotEmpty).toList();
      } else {
        throw Exception('Failed to load stacks: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<DockerContainer>> getStackContainers(String stackName) async {
    final cleanBaseUrl = baseUrl.endsWith('/') 
        ? baseUrl.substring(0, baseUrl.length - 1) 
        : baseUrl;
        
    final url = Uri.parse('$cleanBaseUrl/stacks/$stackName/containers');

    final headers = <String, String>{};
    if (apiKey != null && apiKey!.isNotEmpty) {
      headers['X-API-Key'] = apiKey!;
    }

    try {
      final response = await _client.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => DockerContainer.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load stack containers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> getGitVersion() async {
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse('$cleanBaseUrl/git/version');

    final headers = <String, String>{};
    if (apiKey != null && apiKey!.isNotEmpty) {
      headers['X-API-Key'] = apiKey!;
    }

    try {
      final response = await _client.get(url, headers: headers);
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);
        return jsonMap;
      } else {
        throw Exception('Failed to load git version: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> getSystemInfo() async {
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse('$cleanBaseUrl/info');

    final headers = <String, String>{};
    if (apiKey != null && apiKey!.isNotEmpty) {
      headers['X-API-Key'] = apiKey!;
    }

    try {
      final response = await _client.get(url, headers: headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load system info: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
 
  Future<WebSocketChannel> connectToEvents() async {
    final cleanBaseUrl = baseUrl.endsWith('/') 
        ? baseUrl.substring(0, baseUrl.length - 1) 
        : baseUrl;
        
    String wsUrl = cleanBaseUrl.replaceFirst('http', 'ws');
    if (cleanBaseUrl.startsWith('https')) {
       wsUrl = cleanBaseUrl.replaceFirst('https', 'wss');
    } else if (!cleanBaseUrl.startsWith('http')) {
       // Handle cases where scheme might be missing, default to ws
       wsUrl = 'ws://$cleanBaseUrl';
    } else {
       wsUrl = cleanBaseUrl.replaceFirst('http', 'ws');
    }
    
    wsUrl = '$wsUrl/ws/events?api_key=$apiKey';

    final headers = <String, dynamic>{};
    if (apiKey != null && apiKey!.isNotEmpty) {
      headers['X-API-Key'] = apiKey!;
    }

    if (ignoreSsl) {
      final client = HttpClient();
      client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      try {
        final ws = await WebSocket.connect(wsUrl, headers: headers, customClient: client);
        return IOWebSocketChannel(ws);
      } catch (e) {
        throw Exception('WebSocket connection failed: $e');
      }
    } else {
      return IOWebSocketChannel.connect(Uri.parse(wsUrl), headers: headers);
    }
  }

  Stream<dynamic> pullImageWs(String name, String tag) async* {
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    String wsUrl = cleanBaseUrl.replaceFirst('http', 'ws');
    if (cleanBaseUrl.startsWith('https')) {
       wsUrl = cleanBaseUrl.replaceFirst('https', 'wss');
    } else if (!cleanBaseUrl.startsWith('http')) {
       wsUrl = 'ws://$cleanBaseUrl';
    } else {
       wsUrl = cleanBaseUrl.replaceFirst('http', 'ws');
    }
    
    // Using /ws/images/pull endpoint
    wsUrl = '$wsUrl/ws/images/pull?api_key=$apiKey';

    final headers = <String, dynamic>{};
    if (apiKey != null && apiKey!.isNotEmpty) {
      headers['X-API-Key'] = apiKey!;
    }

    WebSocketChannel channel;
    if (ignoreSsl) {
      final client = HttpClient();
      client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      try {
        final ws = await WebSocket.connect(wsUrl, headers: headers, customClient: client);
        channel = IOWebSocketChannel(ws);
      } catch (e) {
        throw Exception('WebSocket connection failed: $e');
      }
    } else {
      channel = IOWebSocketChannel.connect(Uri.parse(wsUrl), headers: headers);
    }

    // Send request
    final request = json.encode({
      'image': name,
      'tag': tag,
    });
    channel.sink.add(request);

    try {
      await for (final message in channel.stream) {
        if (message is String) {
          try {
            yield json.decode(message);
          } catch (_) {
            yield {'message': message};
          }
        } else {
          yield {'message': message.toString()};
        }
      }
    } catch (e) {
      yield {'error': e.toString()};
    } finally {
      channel.sink.close();
    }
  }

  Future<String> getContainerLogs(String id) async {
    final cleanBaseUrl = baseUrl.endsWith('/') 
        ? baseUrl.substring(0, baseUrl.length - 1) 
        : baseUrl;
        
    final url = Uri.parse('$cleanBaseUrl/containers/$id/logs?stdout=1&stderr=1&tail=100&timestamps=0');

    final headers = <String, String>{};
    if (apiKey != null && apiKey!.isNotEmpty) {
      headers['X-API-Key'] = apiKey!;
    }

    try {
      final response = await _client.get(url, headers: headers);

      if (response.statusCode == 200) {
        // Try parsing as JSON first (custom API wrapper case)
        try {
          final jsonResponse = json.decode(response.body);
          if (jsonResponse is Map && jsonResponse.containsKey('logs')) {
             return jsonResponse['logs'].toString();
          }
        } catch (_) {
          // Not JSON, proceed to standard binary parsing
        }

        return _parseDockerLogs(response.bodyBytes);
      } else {
        throw Exception('Failed to load logs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  String _parseDockerLogs(Uint8List bytes) {
    final buffer = StringBuffer();
    int index = 0;
    final ansiRegex = RegExp(r'\x1B\[[0-9;]*[a-zA-Z]'); // Regex to strip ANSI codes

    while (index < bytes.length) {
      if (index + 8 > bytes.length) {
        String remaining = utf8.decode(bytes.sublist(index), allowMalformed: true);
        buffer.write(remaining.replaceAll(ansiRegex, ''));
        break;
      }
      
      final type = bytes[index];
      // Check for Docker header pattern: [StreamType] 0 0 0 [Size...]
      if ((type == 1 || type == 2) && 
          bytes[index+1] == 0 && 
          bytes[index+2] == 0 && 
          bytes[index+3] == 0) {
          
        int size = (bytes[index + 4] << 24) |
                   (bytes[index + 5] << 16) |
                   (bytes[index + 6] << 8) |
                   (bytes[index + 7]);

        index += 8; // Skip header

        if (index + size > bytes.length) {
           size = bytes.length - index;
        }

        if (size > 0) {
          String chunk = utf8.decode(bytes.sublist(index, index + size), allowMalformed: true);
          buffer.write(chunk.replaceAll(ansiRegex, ''));
          index += size;
        }
      } else {
        // Not a header (maybe TTY mode), treat as raw text
        String chunk = utf8.decode(bytes.sublist(index), allowMalformed: true);
        buffer.write(chunk.replaceAll(ansiRegex, ''));
        break;
      }
    }
    return buffer.toString();
  }

  Future<Map<String, dynamic>> getAvailablePorts() async {
    final cleanBaseUrl = baseUrl.endsWith('/') 
        ? baseUrl.substring(0, baseUrl.length - 1) 
        : baseUrl;
        
    final url = Uri.parse('$cleanBaseUrl/ports/available');

    final headers = <String, String>{};
    if (apiKey != null && apiKey!.isNotEmpty) {
      headers['X-API-Key'] = apiKey!;
    }

    try {
      final response = await _client.get(url, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load available ports: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
