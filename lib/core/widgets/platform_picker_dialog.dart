import 'package:flutter/material.dart';
import '../auth/role_utils.dart';

class PlatformPickerDialog extends StatefulWidget {
  final Function(AppPlatform platform, bool remember) onPlatformSelected;
  final String? roleDescription;
  
  const PlatformPickerDialog({
    Key? key,
    required this.onPlatformSelected,
    this.roleDescription,
  }) : super(key: key);

  @override
  State<PlatformPickerDialog> createState() => _PlatformPickerDialogState();
}

class _PlatformPickerDialogState extends State<PlatformPickerDialog> {
  bool _rememberChoice = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 500 : double.infinity,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.devices,
              size: 48,
              color: Color(0xFF0056B3),
            ),
            const SizedBox(height: 16),
            Text(
              'Selecciona tu aplicación',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.roleDescription != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.roleDescription!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),
            _buildPlatformOption(
              icon: Icons.phone_android,
              title: 'Programa de Excelencia',
              subtitle: 'Permite ejecutar programa de excelencia',
              platform: AppPlatform.mobile,
              isDesktop: isDesktop,
            ),
            const SizedBox(height: 16),
            _buildPlatformOption(
              icon: Icons.computer,
              title: 'Administración',
              subtitle: 'Acceder a Módulo de administración',
              platform: AppPlatform.web,
              isDesktop: isDesktop,
            ),
            const SizedBox(height: 24),
            CheckboxListTile(
              value: _rememberChoice,
              onChanged: (value) {
                setState(() {
                  _rememberChoice = value ?? false;
                });
              },
              title: const Text('Recordar mi elección en este dispositivo'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required AppPlatform platform,
    required bool isDesktop,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
          widget.onPlatformSelected(platform, _rememberChoice);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(isDesktop ? 20 : 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0056B3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: const Color(0xFF0056B3),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}