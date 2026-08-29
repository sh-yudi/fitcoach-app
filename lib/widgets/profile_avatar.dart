import 'dart:convert';

import 'package:flutter/material.dart';

import '../config.dart';
import '../theme.dart';

/// Displays a user profile photo from either a server URL or base64 data.
class ProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final String? base64;
  final double size;
  final IconData fallbackIcon;

  const ProfileAvatar({
    super.key,
    this.photoUrl,
    this.base64,
    this.size = 48,
    this.fallbackIcon = Icons.person,
  });

  @override
  Widget build(BuildContext context) {
    // Server-stored photo URL → load from network.
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      final fullUrl = photoUrl!.startsWith('http')
          ? photoUrl!
          : '${AppConfig.apiBaseUrl}$photoUrl';
      return ClipOval(
        child: Image.network(
          fullUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
        ),
      );
    }

    // Legacy base64 photo → decode and display from memory.
    if (base64 != null && base64!.isNotEmpty) {
      try {
        final bytes = base64Decode(base64!);
        return ClipOval(
          child: Image.memory(bytes, width: size, height: size, fit: BoxFit.cover),
        );
      } catch (_) {}
    }

    return _fallback();
  }

  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.avatarFallback,
      ),
      child: Icon(fallbackIcon, size: size * 0.5, color: Colors.white54),
    );
  }
}
