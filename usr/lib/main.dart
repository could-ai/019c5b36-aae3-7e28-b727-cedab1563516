import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const PrpApp());
}

class PrpApp extends StatelessWidget {
  const PrpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Placement Readiness Platform',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A), // Premium dark blue/slate
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A),
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const DashboardScreen(),
        '/prp/proof': (context) => const ProofScreen(),
      },
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<bool> _steps = List.filled(8, false);
  List<bool> _checklist = List.filled(10, false);
  Map<String, String> _proofLinks = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Steps
    final stepsString = prefs.getString('prp_steps');
    if (stepsString != null) {
      final List<dynamic> decoded = jsonDecode(stepsString);
      _steps = decoded.cast<bool>();
    }

    // Load Checklist
    final checklistString = prefs.getString('prp_checklist');
    if (checklistString != null) {
      final List<dynamic> decoded = jsonDecode(checklistString);
      _checklist = decoded.cast<bool>();
    }

    // Load Proof Links
    final proofString = prefs.getString('prp_final_submission');
    if (proofString != null) {
      final Map<String, dynamic> decoded = jsonDecode(proofString);
      _proofLinks = decoded.cast<String, String>();
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _toggleStep(int index, bool? value) async {
    if (value == null) return;
    setState(() {
      _steps[index] = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('prp_steps', jsonEncode(_steps));
  }

  Future<void> _toggleChecklist(int index, bool? value) async {
    if (value == null) return;
    setState(() {
      _checklist[index] = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('prp_checklist', jsonEncode(_checklist));
  }

  bool get _isShipped {
    final allSteps = _steps.every((s) => s);
    final allChecklist = _checklist.every((c) => c);
    final hasLovable = _proofLinks['lovable']?.isNotEmpty ?? false;
    final hasGithub = _proofLinks['github']?.isNotEmpty ?? false;
    final hasDeployed = _proofLinks['deployed']?.isNotEmpty ?? false;

    return allSteps && allChecklist && hasLovable && hasGithub && hasDeployed;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Placement Readiness Platform'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Chip(
              label: Text(
                _isShipped ? 'Shipped' : 'In Progress',
                style: TextStyle(
                  color: _isShipped ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: _isShipped ? Colors.green : Colors.amber,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isShipped) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.verified, color: Colors.green, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      "You built a real product.\nNot a tutorial. Not a clone.\nA structured tool that solves a real problem.\n\nThis is your proof of work.",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade900,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            _buildSectionHeader("Development Steps (8)"),
            ...List.generate(8, (index) {
              return CheckboxListTile(
                title: Text("Step ${index + 1}"),
                value: _steps[index],
                onChanged: (v) => _toggleStep(index, v),
                dense: true,
              );
            }),

            const SizedBox(height: 24),
            _buildSectionHeader("Readiness Checklist (10)"),
            ...List.generate(10, (index) {
              return CheckboxListTile(
                title: Text("Checklist Item ${index + 1}"),
                value: _checklist[index],
                onChanged: (v) => _toggleChecklist(index, v),
                dense: true,
              );
            }),

            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.pushNamed(context, '/prp/proof');
                // Refresh state when returning from proof page
                _loadData();
              },
              icon: const Icon(Icons.assignment_turned_in),
              label: const Text("Manage Proof & Submission"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }
}

class ProofScreen extends StatefulWidget {
  const ProofScreen({super.key});

  @override
  State<ProofScreen> createState() => _ProofScreenState();
}

class _ProofScreenState extends State<ProofScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lovableController = TextEditingController();
  final _githubController = TextEditingController();
  final _deployedController = TextEditingController();
  
  List<bool> _steps = List.filled(8, false);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _lovableController.dispose();
    _githubController.dispose();
    _deployedController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Steps for display
    final stepsString = prefs.getString('prp_steps');
    if (stepsString != null) {
      final List<dynamic> decoded = jsonDecode(stepsString);
      _steps = decoded.cast<bool>();
    }

    // Load Proof Links
    final proofString = prefs.getString('prp_final_submission');
    if (proofString != null) {
      final Map<String, dynamic> decoded = jsonDecode(proofString);
      _lovableController.text = decoded['lovable'] ?? '';
      _githubController.text = decoded['github'] ?? '';
      _deployedController.text = decoded['deployed'] ?? '';
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveLinks() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final data = {
      'lovable': _lovableController.text.trim(),
      'github': _githubController.text.trim(),
      'deployed': _deployedController.text.trim(),
    };
    
    await prefs.setString('prp_final_submission', jsonEncode(data));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Artifacts saved successfully!')),
      );
    }
  }

  void _copyFinalSubmission() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in valid URLs before copying.')),
      );
      return;
    }

    final text = '''
------------------------------------------
Placement Readiness Platform — Final Submission

Lovable Project: ${_lovableController.text.trim()}
GitHub Repository: ${_githubController.text.trim()}
Live Deployment: ${_deployedController.text.trim()}

Core Capabilities:
- JD skill extraction (deterministic)
- Round mapping engine
- 7-day prep plan
- Interactive readiness scoring
- History persistence
------------------------------------------
''';

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Final Submission copied to clipboard!')),
    );
  }

  String? _validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || !uri.host.isNotEmpty) {
      return 'Please enter a valid URL (e.g., https://...)';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proof of Work'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('A) Step Completion Overview'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: List.generate(8, (index) {
                      final isCompleted = _steps[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Icon(
                              isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: isCompleted ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Step ${index + 1}',
                              style: TextStyle(
                                color: isCompleted ? Colors.black87 : Colors.grey,
                                fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              isCompleted ? 'Completed' : 'Pending',
                              style: TextStyle(
                                color: isCompleted ? Colors.green : Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('B) Artifact Inputs (Required for Ship Status)'),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _lovableController,
                decoration: const InputDecoration(
                  labelText: 'Lovable Project Link',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.favorite_border),
                ),
                validator: _validateUrl,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _githubController,
                decoration: const InputDecoration(
                  labelText: 'GitHub Repository Link',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.code),
                ),
                validator: _validateUrl,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _deployedController,
                decoration: const InputDecoration(
                  labelText: 'Deployed URL',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.rocket_launch),
                ),
                validator: _validateUrl,
              ),

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saveLinks,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Artifacts'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _copyFinalSubmission,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy Final Submission'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF0F172A),
      ),
    );
  }
}
