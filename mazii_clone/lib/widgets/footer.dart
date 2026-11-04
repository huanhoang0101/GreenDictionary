import 'package:flutter/material.dart';
import '../localization/app_strings.dart';

class Footer extends StatelessWidget {
  final AppStrings strings;

  const Footer({
    super.key,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF263238),
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 36,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Text(
                strings.appName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                strings.footerDescription,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 24),

              const Divider(color: Colors.white24),

              const SizedBox(height: 16),

              Text(
                strings.footerCopyright,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}