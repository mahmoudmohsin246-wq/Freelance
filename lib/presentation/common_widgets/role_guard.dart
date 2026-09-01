import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RoleGuard extends StatelessWidget {
  final Widget child;
  final Widget? fallback;

  const RoleGuard({
    super.key,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<dynamic>(context);
    if (authProvider.isAdmin == true) {
      return child;
    }
    return fallback ??
        Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.lock_outline, size: 48, color: Colors.redAccent),
                SizedBox(height: 16),
                Text(
                  'Access Restricted',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Administrator privileges are required to access this section.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        );
  }
}
