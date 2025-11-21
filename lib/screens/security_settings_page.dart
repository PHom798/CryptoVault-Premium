// ============================================
// SECURITY SETTINGS PAGE
// ============================================

import 'package:cryptoo/screens/seed_phrase_backup_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../services/wallet_service.dart';
import 'import_wallet_page.dart';

class SecuritySettingsPage extends StatefulWidget {
  final WalletService walletService;

  const SecuritySettingsPage({required this.walletService});

  @override
  _SecuritySettingsPageState createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  bool _biometricEnabled = false;
  bool _backupCompleted = false;
  bool _biometricAvailable = false;
  List<BiometricType> _availableBiometrics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    final biometricEnabled = await widget.walletService.isBiometricEnabled();
    final backupCompleted = await widget.walletService.isBackupCompleted();
    final biometricAvailable = await widget.walletService.canAuthenticateWithBiometrics();
    final availableBiometrics = await widget.walletService.getAvailableBiometrics();

    if (mounted) {
      setState(() {
        _biometricEnabled = biometricEnabled;
        _backupCompleted = backupCompleted;
        _biometricAvailable = biometricAvailable;
        _availableBiometrics = availableBiometrics;
        _isLoading = false;
      });
    }
  }


  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // Enable biometric
      final authenticated = await widget.walletService.authenticateWithBiometrics();
      if (authenticated) {
        await widget.walletService.setBiometricEnabled(true);
        setState(() {
          _biometricEnabled = true;
        });
        _showSuccessSnackBar('Biometric authentication enabled');
      } else {
        _showErrorSnackBar('Authentication failed');
      }
    } else {
      // Disable biometric - require authentication first
      final authenticated = await widget.walletService.authenticateWithBiometrics();
      if (authenticated) {
        await widget.walletService.setBiometricEnabled(false);
        setState(() {
          _biometricEnabled = false;
        });
        _showSuccessSnackBar('Biometric authentication disabled');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Color(0xFF4AE8AB),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  String _getBiometricTypeText() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (_availableBiometrics.contains(BiometricType.iris)) {
      return 'Iris';
    }
    return 'Biometric';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0B14),
      appBar: AppBar(
        backgroundColor: Color(0xFF0F1018),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Security & Privacy',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: Color(0xFF4AE8AB),
        ),
      ): ListView(
        padding: EdgeInsets.all(20),
        children: [
          // Backup Warning Card
          if (!_backupCompleted)
            Container(
              margin: EdgeInsets.only(bottom: 20),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFEF4444).withOpacity(0.1),
                    Color(0xFFF59E0B).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Color(0xFFEF4444).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Backup Required!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your wallet is not backed up. If you lose your device, you will lose access to your funds forever.',
                    style: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>  SeedPhraseBackupPage(
                              walletService: widget.walletService,
                              onBackupComplete: () {
                                setState(() {
                                  _backupCompleted = true;
                                });
                              },
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFF59E0B),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Backup Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Authentication Section
          _buildSectionTitle('Authentication'),
          SizedBox(height: 12),

          _buildSettingCard(
            icon: Icons.fingerprint,
            title: _getBiometricTypeText(),
            subtitle: _biometricAvailable
                ? (_biometricEnabled ? 'Required to access wallet' : 'Tap to enable')
                : 'Not available on this device',
            trailing: _biometricAvailable
                ? Switch(
              value: _biometricEnabled,
              onChanged: _toggleBiometric,
              activeColor: Color(0xFF4AE8AB),
            )
                : Icon(Icons.block, color: Color(0xFF6B7280)),
          ),

          SizedBox(height: 20),

          // Backup & Recovery Section
          _buildSectionTitle('Backup & Recovery'),
          SizedBox(height: 12),

          _buildSettingCard(
            icon: Icons.key,
            title: 'Recovery Phrase',
            subtitle: _backupCompleted ? 'Backed up' : 'Not backed up',
            trailing: Icon(
              _backupCompleted ? Icons.check_circle : Icons.arrow_forward_ios,
              color: _backupCompleted ? Color(0xFF4AE8AB) : Color(0xFF6B7280),
              size: _backupCompleted ? 24 : 16,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SeedPhraseBackupPage(
                    walletService: widget.walletService,
                    onBackupComplete: () {
                      setState(() {
                        _backupCompleted = true;
                      });
                    },
                  ),
                ),
              );
            },
          ),

          SizedBox(height: 12),

          _buildSettingCard(
            icon: Icons.restore,
            title: 'Import Wallet',
            subtitle: 'Recover wallet from seed phrase',
            trailing: Icon(Icons.arrow_forward_ios, color: Color(0xFF6B7280), size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImportWalletPage(walletService: widget.walletService),
                ),
              );
            },
          ),

          SizedBox(height: 20),

          // Advanced Section
          _buildSectionTitle('Advanced'),
          SizedBox(height: 12),

          _buildSettingCard(
            icon: Icons.lock_outline,
            title: 'Change PIN',
            subtitle: 'Coming soon',
            trailing: Icon(Icons.arrow_forward_ios, color: Color(0xFF6B7280), size: 16),
            onTap: () {
              _showErrorSnackBar('Feature coming soon');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFF1A1B26),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Color(0xFF2D2E3F),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Color(0xFF4AE8AB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Color(0xFF4AE8AB), size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

