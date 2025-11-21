// ============================================
// IMPORT WALLET PAGE
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/wallet_service.dart';

class ImportWalletPage extends StatefulWidget {
  final WalletService walletService;

  const ImportWalletPage({required this.walletService});

  @override
  _ImportWalletPageState createState() => _ImportWalletPageState();
}

class _ImportWalletPageState extends State<ImportWalletPage> {
  final List<TextEditingController> _controllers = List.generate(12, (_) => TextEditingController());
  bool _isImporting = false;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _importWallet() async {
    // Get all words
    final words = _controllers.map((c) => c.text.trim().toLowerCase()).toList();

    // Validate all fields are filled
    if (words.any((word) => word.isEmpty)) {
      _showErrorDialog('Please fill in all 12 words');
      return;
    }

    // Join into mnemonic
    final mnemonic = words.join(' ');

    setState(() {
      _isImporting = true;
    });

    try {
      final success = await widget.walletService.recoverFromMnemonic(mnemonic);

      setState(() {
        _isImporting = false;
      });

      if (success) {
        // Show success dialog
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
                Text('Wallet Imported!', style: TextStyle(color: Colors.white)),
              ],
            ),
            content: Text(
              'Your wallet has been successfully imported.',
              style: TextStyle(color: Color(0xFF9CA3AF)),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to settings
                  Navigator.pop(context); // Go back to main screen
                },
                child: Text('Done', style: TextStyle(color: Color(0xFF4AE8AB))),
              ),
            ],
          ),
        );
      } else {
        _showErrorDialog('Invalid recovery phrase. Please check and try again.');
      }
    } catch (e) {
      setState(() {
        _isImporting = false;
      });
      _showErrorDialog('Import failed: ${e.toString()}');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1B26),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Color(0xFF2D2E3F)),
        ),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 24),
            SizedBox(width: 12),
            Text('Error', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(message, style: TextStyle(color: Color(0xFF9CA3AF))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: Color(0xFF4AE8AB))),
          ),
        ],
      ),
    );
  }

  void _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null) {
      final words = data.text!.trim().split(RegExp(r'\s+'));
      if (words.length == 12) {
        for (int i = 0; i < 12; i++) {
          _controllers[i].text = words[i].toLowerCase();
        }
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pasted 12 words from clipboard'),
            backgroundColor: Color(0xFF4AE8AB),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: EdgeInsets.all(16),
          ),
        );
      } else {
        _showErrorDialog('Invalid format. Please paste exactly 12 words.');
      }
    }
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
          'Import Wallet',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.paste, color: Color(0xFF4AE8AB)),
            onPressed: _pasteFromClipboard,
            tooltip: 'Paste from clipboard',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                            'Never share your recovery phrase with anyone',
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

                  Text(
                    'Enter your 12-word recovery phrase',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 16),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF1A1B26),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Color(0xFF2D2E3F)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              alignment: Alignment.center,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _controllers[index],
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'word',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 14,
                                  ),
                                ),
                                autocorrect: false,
                                textCapitalization: TextCapitalization.none,
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
          ),

          // Import button
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFF0F1018),
              border: Border(
                top: BorderSide(color: Color(0xFF2D2E3F), width: 1),
              ),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isImporting ? null : _importWallet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4AE8AB),
                    disabledBackgroundColor: Color(0xFF2D2E3F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isImporting
                      ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    'Import Wallet',
                    style: TextStyle(
                      color: Color(0xFF0A0B14),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}