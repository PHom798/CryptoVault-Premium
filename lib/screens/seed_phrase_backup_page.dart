// lib/screens/seed_phrase_backup_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../services/wallet_service.dart';

class SeedPhraseBackupPage extends StatefulWidget {
  final WalletService walletService;
  final VoidCallback onBackupComplete;

  const SeedPhraseBackupPage({
    Key? key,
    required this.walletService,
    required this.onBackupComplete,
  }) : super(key: key);

  @override
  _SeedPhraseBackupPageState createState() => _SeedPhraseBackupPageState();
}

class _SeedPhraseBackupPageState extends State<SeedPhraseBackupPage> {
  int _currentStep = 0;
  bool _acknowledgedRisks = false;
  bool _seedPhraseRevealed = false;
  List<String> _mnemonicWords = [];
  bool _isVerifying = false;
  List<int> _selectedIndices = [];
  List<int> _correctIndices = [];

  @override
  void initState() {
    super.initState();
    _loadMnemonic();
  }

  Future<void> _loadMnemonic() async {
    final mnemonic = widget.walletService.mnemonic;
    if (mnemonic != null) {
      setState(() {
        _mnemonicWords = mnemonic.split(' ');
      });
    }
  }

  void _proceedToNextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _revealSeedPhrase() async {
    // Require authentication before revealing
    final authenticated = await widget.walletService.authenticateWithBiometrics();
    if (authenticated) {
      setState(() {
        _seedPhraseRevealed = true;
      });
      HapticFeedback.mediumImpact();
    } else {
      _showErrorSnackBar('Authentication required to view seed phrase');
    }
  }

  void _startVerification() {
    // Select 3 random words to verify
    final random = Random();
    final indices = <int>[];
    while (indices.length < 3) {
      final index = random.nextInt(_mnemonicWords.length);
      if (!indices.contains(index)) {
        indices.add(index);
      }
    }
    indices.sort();

    setState(() {
      _correctIndices = indices;
      _selectedIndices = [];
      _isVerifying = true;
      _currentStep = 2;
    });
  }

  void _verifyWord(int wordIndex) {
    setState(() {
      _selectedIndices.add(wordIndex);
    });

    // Check if verification is complete
    if (_selectedIndices.length == 3) {
      _checkVerification();
    }
  }

  void _checkVerification() {
    bool correct = true;
    for (int i = 0; i < 3; i++) {
      if (_selectedIndices[i] != _correctIndices[i]) {
        correct = false;
        break;
      }
    }

    if (correct) {
      _completeBackup();
    } else {
      _showErrorSnackBar('Incorrect words. Please try again.');
      setState(() {
        _selectedIndices = [];
      });
    }
  }

  Future<void> _completeBackup() async {
    await widget.walletService.markBackupCompleted();
    widget.onBackupComplete();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1B26),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Color(0xFF2D2E3F)),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF4AE8AB), size: 32),
            SizedBox(width: 12),
            Text('Backup Complete!', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'Your wallet has been successfully backed up. Keep your recovery phrase safe!',
          style: TextStyle(color: Color(0xFF9CA3AF)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to settings
            },
            child: Text('Done', style: TextStyle(color: Color(0xFF4AE8AB))),
          ),
        ],
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
          'Backup Wallet',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: _buildCurrentStep(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Color(0xFF0F1018),
        border: Border(
          bottom: BorderSide(color: Color(0xFF2D2E3F), width: 1),
        ),
      ),
      child: Row(
        children: [
          _buildStepIndicator(0, 'Secure'),
          _buildStepLine(0),
          _buildStepIndicator(1, 'Backup'),
          _buildStepLine(1),
          _buildStepIndicator(2, 'Verify'),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    bool isActive = _currentStep >= step;
    bool isCurrent = _currentStep == step;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive ? Color(0xFF4AE8AB) : Color(0xFF2D2E3F),
              shape: BoxShape.circle,
              border: Border.all(
                color: isCurrent ? Color(0xFF4AE8AB) : Colors.transparent,
                width: 2,
              ),
            ),
            child: Center(
              child: isActive
                  ? Icon(Icons.check, color: Color(0xFF0A0B14), size: 16)
                  : Text(
                '${step + 1}',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Color(0xFF4AE8AB) : Color(0xFF6B7280),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int step) {
    bool isActive = _currentStep > step;
    return Expanded(
      child: Container(
        height: 2,
        margin: EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: isActive ? Color(0xFF4AE8AB) : Color(0xFF2D2E3F),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildSecurityWarning();
      case 1:
        return _buildSeedPhraseDisplay();
      case 2:
        return _buildVerificationStep();
      default:
        return Container();
    }
  }

  Widget _buildSecurityWarning() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.shield_outlined, color: Color(0xFFF59E0B), size: 64),
        SizedBox(height: 20),
        Text(
          'Secure Your Wallet',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Your recovery phrase is the key to your wallet. Follow these rules:',
          style: TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 16,
            height: 1.5,
          ),
        ),
        SizedBox(height: 24),

        _buildWarningItem(
          icon: Icons.edit_off,
          title: 'Write it down',
          description: 'Never store it digitally. Use pen and paper.',
        ),
        _buildWarningItem(
          icon: Icons.visibility_off,
          title: 'Keep it private',
          description: 'Never share it with anyone, including support staff.',
        ),
        _buildWarningItem(
          icon: Icons.security,
          title: 'Store safely',
          description: 'Keep it in a secure location, like a safe.',
        ),
        _buildWarningItem(
          icon: Icons.backup,
          title: 'Make copies',
          description: 'Store multiple copies in different secure locations.',
        ),

        SizedBox(height: 32),

        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFFEF4444).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFFEF4444).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Checkbox(
                value: _acknowledgedRisks,
                onChanged: (value) {
                  setState(() {
                    _acknowledgedRisks = value ?? false;
                  });
                },
                activeColor: Color(0xFF4AE8AB),
              ),
              Expanded(
                child: Text(
                  'I understand that if I lose my recovery phrase, I will lose access to my wallet forever.',
                  style: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _acknowledgedRisks ? _proceedToNextStep : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4AE8AB),
              disabledBackgroundColor: Color(0xFF2D2E3F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Continue',
              style: TextStyle(
                color: _acknowledgedRisks ? Color(0xFF0A0B14) : Color(0xFF6B7280),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWarningItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1B26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF2D2E3F)),
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
                  description,
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeedPhraseDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Recovery Phrase',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Write down these 12 words in order. You will need them to recover your wallet.',
          style: TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 16,
            height: 1.5,
          ),
        ),
        SizedBox(height: 24),

        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Color(0xFF1A1B26),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Color(0xFF2D2E3F)),
          ),
          child: Column(
            children: [
              if (!_seedPhraseRevealed)
                Column(
                  children: [
                    Icon(Icons.visibility_off, color: Color(0xFF6B7280), size: 48),
                    SizedBox(height: 16),
                    Text(
                      'Tap to reveal',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 16),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _revealSeedPhrase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4AE8AB),
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Reveal Seed Phrase',
                        style: TextStyle(
                          color: Color(0xFF0A0B14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _mnemonicWords.length,
                  itemBuilder: (context, index) {
                    return Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFF252736),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Color(0xFF2D2E3F)),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${index + 1}.',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            _mnemonicWords[index],
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),

        if (_seedPhraseRevealed) ...[
          SizedBox(height: 24),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFF59E0B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFFF59E0B).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Make sure nobody can see your screen',
                    style: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _startVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4AE8AB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'I\'ve Written It Down',
                style: TextStyle(
                  color: Color(0xFF0A0B14),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVerificationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verify Your Backup',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Select the correct words in order to verify your backup.',
          style: TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 16,
            height: 1.5,
          ),
        ),
        SizedBox(height: 24),

        // Show which words need to be selected
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFF1A1B26),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFF2D2E3F)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select words:',
                style: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _correctIndices.asMap().entries.map((entry) {
                  int idx = entry.key;
                  int wordIndex = entry.value;
                  bool isSelected = _selectedIndices.length > idx;

                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? Color(0xFF4AE8AB).withOpacity(0.1) : Color(0xFF252736),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? Color(0xFF4AE8AB) : Color(0xFF2D2E3F),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      isSelected
                          ? '${wordIndex + 1}. ${_mnemonicWords[_selectedIndices[idx]]}'
                          : '${wordIndex + 1}. ___',
                      style: TextStyle(
                        color: isSelected ? Color(0xFF4AE8AB) : Color(0xFF6B7280),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        SizedBox(height: 24),

        // All available words shuffled
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFF1A1B26),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFF2D2E3F)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available words:',
                style: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _getShuffledWords().map((wordData) {
                  bool isUsed = _selectedIndices.contains(wordData['index']);
                  bool isDisabled = _selectedIndices.length >= 3;

                  return GestureDetector(
                    onTap: isUsed || isDisabled ? null : () => _verifyWord(wordData['index']),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isUsed ? Color(0xFF252736).withOpacity(0.3) : Color(0xFF252736),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isUsed ? Color(0xFF2D2E3F).withOpacity(0.3) : Color(0xFF2D2E3F),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        wordData['word'],
                        style: TextStyle(
                          color: isUsed ? Color(0xFF6B7280).withOpacity(0.3) : Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          decoration: isUsed ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getShuffledWords() {
    final words = _mnemonicWords.asMap().entries.map((entry) {
      return {'index': entry.key, 'word': entry.value};
    }).toList();
    words.shuffle(Random());
    return words;
  }
}