import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import '../../widgets/ad_banner.dart';

class DeveloperScreen extends StatefulWidget {
  const DeveloperScreen({super.key});

  @override
  State<DeveloperScreen> createState() => _DeveloperScreenState();
}

class _DeveloperScreenState extends State<DeveloperScreen> {
  DeveloperInfo? _developer;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await ApiClient.instance.getDeveloperInfo();
      if (!mounted) return;
      setState(() {
        _developer = d;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Developer Information')),
      body: SafeArea(
        child: _developer == null
            ? (_error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cloud_off, color: AppColors.textSecondary, size: 48),
                          const SizedBox(height: 16),
                          Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                          const SizedBox(height: 20),
                          FilledButton(onPressed: _load, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  )
                : Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5)))
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  Center(
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(Icons.code, color: AppColors.onPrimary, size: 42),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      _developer!.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      _developer!.role,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceLight),
                    ),
                    child: Column(
                      children: [
                        _DevRow(icon: Icons.link, label: 'Website', value: _developer!.website),
                        Divider(height: 1, color: AppColors.surfaceLight),
                        _DevRow(icon: Icons.mail_outline, label: 'Email', value: _developer!.email),
                        Divider(height: 1, color: AppColors.surfaceLight),
                        _DevRow(icon: Icons.code, label: 'GitHub', value: _developer!.github),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'This information is provided by the app developer and is the same for all users.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  const AdBanner(),
                ],
              ),
      ),
    );
  }
}

class _DevRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DevRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
