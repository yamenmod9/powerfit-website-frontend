import 'package:flutter/material.dart';
import '../../../core/utils/api_debugger.dart';
import '../../../core/api/api_endpoints.dart';

/// Debug screen to test backend connectivity and API endpoints
class ApiDebugScreen extends StatefulWidget {
  const ApiDebugScreen({super.key});

  @override
  State<ApiDebugScreen> createState() => _ApiDebugScreenState();
}

class _ApiDebugScreenState extends State<ApiDebugScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isTesting = false;
  String _result = '';

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _testBackend() async {
    setState(() {
      _isTesting = true;
      _result = 'Testing backend connection...\n\n';
    });

    final results = await ApiDebugger.testBackendConnection(ApiEndpoints.baseUrl);

    setState(() {
      _result += '\n\n📋 Results:\n';
      _result += results.toString();
      _isTesting = false;
    });
  }

  Future<void> _testLogin() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _result = '⚠️ Please enter username and password';
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _result = 'Testing login...\n\n';
    });

    final results = await ApiDebugger.testLogin(
      baseUrl: ApiEndpoints.baseUrl,
      username: _usernameController.text,
      password: _passwordController.text,
    );

    setState(() {
      _result += '\n\n📋 Results:\n';
      _result += results.toString();
      _isTesting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Debug Tool'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Backend Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Backend Configuration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Base URL: ${ApiEndpoints.baseUrl}'),
                    Text('Login Endpoint: ${ApiEndpoints.login}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Test Backend Button
            ElevatedButton.icon(
              onPressed: _isTesting ? null : _testBackend,
              icon: const Icon(Icons.wifi),
              label: const Text('Test Backend Connection'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),

            // Login Test
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Login',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isTesting ? null : _testLogin,
                      icon: const Icon(Icons.login),
                      label: const Text('Test Login'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Results
            if (_result.isNotEmpty) ...[
              const Text(
                'Results:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF16203A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  _result,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],

            if (_isTesting)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
