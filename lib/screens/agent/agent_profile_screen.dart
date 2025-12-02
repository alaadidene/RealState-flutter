import 'package:flutter/material.dart';

class AgentProfileScreen extends StatelessWidget {
  final String agentId;
  const AgentProfileScreen({super.key, required this.agentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agent Profile')),
      body: Center(
        child: Text('Agent profile for: $agentId'),
      ),
    );
  }
}
