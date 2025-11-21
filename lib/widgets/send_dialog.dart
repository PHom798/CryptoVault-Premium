// lib/widgets/send_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/wallet_service.dart';
import 'dart:async';

class EnhancedSendDialog extends StatefulWidget {
  final WalletService walletService;
  final VoidCallback onTransactionComplete;

  const EnhancedSendDialog({
    Key? key,
    required this.walletService,
    required this.onTransactionComplete,
  }) : super(key: key);

  @override
  _EnhancedSendDialogState createState() => _EnhancedSendDialogState();
}

class _EnhancedSendDialogState extends State<EnhancedSendDialog> {
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isLoading = false;
  String _balance = "0.0000";

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadBalance() async {
    try {
      final balance = await widget.walletService.getBalance();
      if (mounted) {
        setState(() {
          _balance = balance;
        });
      }
    } catch (e) {
      print("Error loading balance: $e");
    }
  }

  Future<void> _sendTransaction() async {
    print("🎬 SEND_DIALOG: _sendTransaction() method called - FIXED VERSION");

    if (_addressController.text.isEmpty || _amountController.text.isEmpty) {
      _showErrorDialog("Please fill in all fields");
      return;
    }

    if (!_addressController.text.startsWith('0x') || _addressController.text.length != 42) {
      _showErrorDialog("Invalid Ethereum address");
      return;
    }

    double? amount;
    try {
      amount = double.parse(_amountController.text);
      if (amount <= 0) {
        _showErrorDialog("Amount must be greater than 0");
        return;
      }
      if (amount > double.parse(_balance)) {
        _showErrorDialog("Insufficient balance");
        return;
      }
    } catch (e) {
      _showErrorDialog("Invalid amount");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String? txHash;

    // Get the root navigator context BEFORE any async operations
    final navigatorContext = Navigator.of(context, rootNavigator: true).context;

    try {
      print("SEND_DIALOG: About to call sendEth()");

      txHash = await widget.walletService.sendEth(
        toAddress: _addressController.text,
        amount: amount,
      );

      print("SEND_DIALOG: Transaction sent! Hash: $txHash");

      if (!mounted) {
        print("SEND_DIALOG: Widget unmounted, cannot update UI");
        return;
      }

      print("SEND_DIALOG: Setting loading to false");
      setState(() {
        _isLoading = false;
      });

      print("SEND_DIALOG: About to close send dialog");

      // Close send dialog first
      Navigator.of(context).pop();
      print("SEND_DIALOG: Send dialog closed successfully");

      // Use the saved root navigator context to show the status dialog
      // This context remains valid even after the send dialog is closed
      print("SEND_DIALOG: Now showing TransactionStatusDialog");

      showDialog(
        context: navigatorContext,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          print("SEND_DIALOG: TransactionStatusDialog builder executing");
          return TransactionStatusDialog(
            txHash: txHash!,
            walletService: widget.walletService,
            onComplete: widget.onTransactionComplete,
          );
        },
      ).then((value) {
        print("SEND_DIALOG: TransactionStatusDialog closed");
      });
      print("SEND_DIALOG: showDialog() call completed");

    } catch (e, stackTrace) {
      print("SEND_DIALOG: Transaction error: $e");
      print("SEND_DIALOG: Stack trace: $stackTrace");

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog("Transaction failed: ${e.toString()}");
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1B26),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Color(0xFF2D2E3F), width: 1),
        ),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 24),
            SizedBox(width: 12),
            Text("Error", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(message, style: TextStyle(color: Color(0xFF9CA3AF))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: TextStyle(color: Color(0xFF4AE8AB))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
                  'Send ETH',
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

          Container(
            margin: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1A1B26),
                  Color(0xFF252736),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Color(0xFF4AE8AB).withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Available Balance:", style: TextStyle(color: Color(0xFF9CA3AF))),
                Text(
                  "$_balance ETH",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF4AE8AB),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recipient Address',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Color(0xFF1A1B26),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Color(0xFF2D2E3F)),
                    ),
                    child: TextField(
                      controller: _addressController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: '0x... or ENS name',
                        hintStyle: TextStyle(color: Color(0xFF6B7280)),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  SizedBox(height: 28),
                  Text(
                    'Amount (ETH)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Color(0xFF1A1B26),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Color(0xFF2D2E3F)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: '0.00',
                              hintStyle: TextStyle(color: Color(0xFF6B7280)),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        Text("ETH", style: TextStyle(color: Color(0xFF4AE8AB), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  SizedBox(height: 40),
                  Container(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendTransaction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4AE8AB),
                        disabledBackgroundColor: Color(0xFF2D2E3F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                        'Send Transaction',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A0B14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// TRANSACTION STATUS DIALOG
// ============================================

class TransactionStatusDialog extends StatefulWidget {
  final String txHash;
  final WalletService walletService;
  final VoidCallback onComplete;

  const TransactionStatusDialog({
    Key? key,
    required this.txHash,
    required this.walletService,
    required this.onComplete,
  }) : super(key: key);

  @override
  _TransactionStatusDialogState createState() => _TransactionStatusDialogState();
}

class _TransactionStatusDialogState extends State<TransactionStatusDialog> {
  String _status = 'pending'; // pending, confirmed, failed, timeout
  int _secondsElapsed = 0;
  Timer? _monitoringTimer;
  int _attemptCount = 0;

  @override
  void initState() {
    super.initState();
    print("STATUS_DIALOG: Starting transaction monitoring for: ${widget.txHash}");
    _startMonitoring();
  }

  void _startMonitoring() {
    print("⚙️ STATUS_DIALOG: _startMonitoring() called");
    // Check every 3 seconds (Sepolia can be slow)
    _monitoringTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
      if (!mounted) {
        print("STATUS_DIALOG: Widget unmounted, canceling timer");
        timer.cancel();
        return;
      }

      _attemptCount++;

      if (mounted) {
        setState(() {
          _secondsElapsed = _attemptCount * 3;
        });
      }

      print("STATUS_DIALOG: Attempt $_attemptCount ($_secondsElapsed seconds) - Checking transaction...");

      try {
        final receipt = await widget.walletService.getTransactionReceipt(widget.txHash);

        if (receipt != null) {
          print("STATUS_DIALOG: Receipt found! Status: ${receipt.status}");
          timer.cancel();

          final success = receipt.status == true;

          if (mounted) {
            setState(() {
              _status = success ? 'confirmed' : 'failed';
            });

            if (success) {
              print("🎉 STATUS_DIALOG: Transaction confirmed! Updating balance...");
              // Update balance
              widget.onComplete();

              // Auto-close after 3 seconds
              await Future.delayed(Duration(seconds: 3));
              if (mounted) {
                Navigator.of(context).pop();
              }
            } else {
              print("STATUS_DIALOG: Transaction failed on blockchain");
            }
          }
          return;
        } else {
          print("TATUS_DIALOG: No receipt yet, transaction still pending...");
        }

        // Timeout after 2 minutes (40 attempts × 3 seconds)
        if (_attemptCount >= 40) {
          print("STATUS_DIALOG: Timeout reached after $_secondsElapsed seconds");
          timer.cancel();
          if (mounted) {
            setState(() {
              _status = 'timeout';
            });
          }
        }

      } catch (e) {
        print("STATUS_DIALOG: Error checking receipt: $e");
        // Continue checking even if there's an error
      }
    });
  }

  @override
  void dispose() {
    print("TATUS_DIALOG: Stopping transaction monitoring");
    _monitoringTimer?.cancel();
    super.dispose();
  }

  Color _getStatusColor() {
    switch (_status) {
      case 'confirmed':
        return Color(0xFF4AE8AB);
      case 'failed':
        return Color(0xFFEF4444);
      case 'timeout':
        return Color(0xFFF59E0B);
      default:
        return Color(0xFF60A5FA);
    }
  }

  IconData _getStatusIcon() {
    switch (_status) {
      case 'confirmed':
        return Icons.check_circle;
      case 'failed':
        return Icons.error;
      case 'timeout':
        return Icons.access_time;
      default:
        return Icons.rocket_launch;
    }
  }

  String _getStatusTitle() {
    switch (_status) {
      case 'confirmed':
        return 'Transaction Confirmed!';
      case 'failed':
        return 'Transaction Failed';
      case 'timeout':
        return 'Still Processing';
      default:
        return 'Transaction Sent!';
    }
  }

  String _getStatusMessage() {
    switch (_status) {
      case 'confirmed':
        return 'Your transaction has been confirmed on the blockchain.';
      case 'failed':
        return 'The transaction was rejected by the network. Your funds are safe.';
      case 'timeout':
        return 'Transaction is taking longer than expected. It may still be processing. Check Etherscan for real-time status.';
      default:
        return 'Confirming on blockchain... ($_secondsElapsed seconds elapsed)';
    }
  }

  @override
  Widget build(BuildContext context) {
    print("🎨 STATUS_DIALOG: build() called with status: $_status");
    return WillPopScope(
      onWillPop: () async {
        return _status != 'pending';
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F1018),
                Color(0xFF1A1B26),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: _getStatusColor().withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _getStatusColor().withOpacity(0.1),
                blurRadius: 40,
                spreadRadius: 0,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with Status Icon
              Container(
                padding: EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _getStatusColor().withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  children: [
                    // Animated Status Icon
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _getStatusColor().withOpacity(0.2),
                            _getStatusColor().withOpacity(0.05),
                          ],
                        ),
                        border: Border.all(
                          color: _getStatusColor().withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: _status == 'pending'
                            ? SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: _getStatusColor(),
                          ),
                        )
                            : Icon(
                          _getStatusIcon(),
                          color: _getStatusColor(),
                          size: 36,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    // Status Title
                    Text(
                      _getStatusTitle(),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    // Status Message
                    Text(
                      _getStatusMessage(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF9CA3AF),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_status == 'pending') ...[
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Color(0xFF1A1B26),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getStatusColor().withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: _getStatusColor(),
                            ),
                            SizedBox(width: 8),
                            Text(
                              "$_secondsElapsed seconds",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _getStatusColor(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            backgroundColor: Color(0xFF2D2E3F),
                            valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor()),
                            minHeight: 3,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Transaction Hash Section
              Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Color(0xFF1A1B26),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Color(0xFF2D2E3F),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Color(0xFF4AE8AB).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.tag,
                                  size: 16,
                                  color: Color(0xFF4AE8AB),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                "Transaction Hash",
                                style: TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color(0xFF0F1018),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Color(0xFF4AE8AB).withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${widget.txHash.substring(0, 10)}...${widget.txHash.substring(widget.txHash.length - 8)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF4AE8AB),
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                InkWell(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: widget.txHash));
                                    HapticFeedback.lightImpact();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.white, size: 20),
                                            SizedBox(width: 12),
                                            Text('Copied to clipboard!'),
                                          ],
                                        ),
                                        backgroundColor: Color(0xFF4AE8AB),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        margin: EdgeInsets.all(16),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF4AE8AB).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.copy_outlined,
                                      size: 16,
                                      color: Color(0xFF4AE8AB),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Etherscan Button
                    if (_status != 'pending') ...[
                      SizedBox(height: 16),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(
                              text: 'https://sepolia.etherscan.io/tx/${widget.txHash}'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.link, color: Colors.white, size: 20),
                                  SizedBox(width: 12),
                                  Text('Etherscan link copied!'),
                                ],
                              ),
                              backgroundColor: Color(0xFF60A5FA),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: EdgeInsets.all(16),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF60A5FA).withOpacity(0.1),
                                Color(0xFF60A5FA).withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Color(0xFF60A5FA).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.open_in_new,
                                size: 18,
                                color: Color(0xFF60A5FA),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'View on Etherscan',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF60A5FA),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Action Buttons
                    if (_status != 'pending') ...[
                      SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _status == 'confirmed'
                                ? Color(0xFF4AE8AB)
                                : Color(0xFF2D2E3F),
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            _status == 'confirmed' ? 'Done' : 'Close',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _status == 'confirmed'
                                  ? Color(0xFF0A0B14)
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],

                    // Check Again Button for Timeout
                    if (_status == 'timeout') ...[
                      SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _status = 'pending';
                              _attemptCount = 0;
                              _secondsElapsed = 0;
                            });
                            _startMonitoring();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            side: BorderSide(
                              color: Color(0xFFF59E0B).withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            'Check Again',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}