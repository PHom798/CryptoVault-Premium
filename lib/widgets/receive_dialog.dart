// lib/widgets/receive_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EnhancedReceiveDialog extends StatelessWidget {
  final String walletAddress;

  const EnhancedReceiveDialog({Key? key, required this.walletAddress}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.7,
      decoration: BoxDecoration(
        color: Color(0xFF0F1018),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        border: Border.all(
          color: Color(0xFF2D2E3F),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: Color(0xFF2D2E3F),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Receive ETH',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SizedBox(height: 20),

                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF1A1B26),
                          Color(0xFF252736),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Color(0xFF2D2E3F),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.qr_code,
                          size: 140,
                          color: Color(0xFF4AE8AB),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'QR Code for: ${walletAddress.isNotEmpty ? walletAddress.substring(0, 6) + "..." + walletAddress.substring(walletAddress.length - 4) : "Loading..."}',
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFF1A1B26),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Color(0xFF2D2E3F)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            walletAddress.isNotEmpty ? walletAddress : 'Loading wallet address...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontFamily: 'monospace',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            if (walletAddress.isNotEmpty) {
                              Clipboard.setData(ClipboardData(text: walletAddress));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Address copied to clipboard!'),
                                  backgroundColor: Color(0xFF4AE8AB),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin: EdgeInsets.all(16),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                            HapticFeedback.lightImpact();
                          },
                          icon: Icon(Icons.copy_outlined, size: 20, color: Color(0xFF4AE8AB)),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFF4AE8AB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Color(0xFF4AE8AB).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFF4AE8AB),
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Only send ETH (Sepolia testnet) to this address. Other tokens may be lost forever.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF9CA3AF),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}