// Enhanced Premium Wallet Dashboard with Blockchain Visualizations
import 'dart:async';
import 'dart:math';
import 'package:cryptoo/screens/security_settings_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/wallet_service.dart';
import '../widgets/receive_dialog.dart';
import '../widgets/send_dialog.dart';

class WalletDashboard extends StatefulWidget {
  @override
  _WalletDashboardState createState() => _WalletDashboardState();
}

class _WalletDashboardState extends State<WalletDashboard>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _networkController;
  late AnimationController _cardController;
  late AnimationController _securityController;
  late AnimationController _pulseController;
  late AnimationController _nodeController;
  late AnimationController _shieldController;

  late Animation<double> _networkAnimation;
  late Animation<double> _cardAnimation;
  late Animation<double> _securityAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _nodeAnimation;
  late Animation<double> _shieldAnimation;

  bool _isBalanceVisible = true;
  int _selectedIndex = 0;

  final WalletService _walletService = WalletService();
  String _ethBalance = "0.0000";
  String _walletAddress = "";

  Timer? _refreshTimer;
  bool _isRefreshing = false;
  DateTime? _lastRefresh;

  // Security & Network state
  int _activeNodes = 12;
  double _networkStrength = 0.92;
  bool _isSecure = true;
  String _securityLevel = "Military Grade";

  // Blockchain network nodes for visualization
  List<NetworkNode> nodes = [];
  List<NodeConnection> connections = [];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeBlockchainNetwork();
    _walletService.addListener(_onWalletStateChanged);
    _initializeWallet();

    _refreshTimer = Timer.periodic(Duration(seconds: 15), (timer) {
      if (_walletService.isInitialized && !_isRefreshing) {
        _updateWalletData();
      }
    });
  }

  void _showSendDialog() {
    print("Opening send dialog...");

    if (!_walletService.isInitialized) {
      _showErrorSnackBar("Wallet is still initializing. Please wait.");
      return;
    }

    // Remove the listener temporarily to avoid unnecessary rebuilds
    _walletService.removeListener(_onWalletStateChanged);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        print("Send dialog builder called");
        return EnhancedSendDialog(
          walletService: _walletService,
          onTransactionComplete: () {
            print("DASHBOARD: onTransactionComplete callback fired!");
            _updateWalletData();
          },
        );
      },
    ).then((value) {
      print("DASHBOARD: Send dialog closed");

      // Re-add the listener after dialog closes
      _walletService.addListener(_onWalletStateChanged);

      // The send_dialog.dart now handles showing the TransactionStatusDialog
      // We just need to update wallet data when the dialog closes
      _updateWalletData();
    });
  }

  void _showReceiveDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          EnhancedReceiveDialog(walletAddress: _walletAddress),
    );
  }

  void _initializeBlockchainNetwork() {
    final random = Random();
    // Create network nodes
    for (int i = 0; i < 8; i++) {
      nodes.add(NetworkNode(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 8 + 4,
        isActive: random.nextBool(),
        pulseDelay: random.nextDouble() * 2000,
      ));
    }

    // Create connections between nodes
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        if (random.nextDouble() > 0.6) {
          connections.add(NodeConnection(
            startNode: i,
            endNode: j,
            strength: random.nextDouble(),
          ));
        }
      }
    }
  }

  void _onWalletStateChanged() {
    if (mounted) {
      setState(() {});
      if (_walletService.isInitialized) {
        _updateWalletData();
      }
    }
  }

  void _setupAnimations() {
    _networkController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _cardController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _securityController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _nodeController = AnimationController(
      duration: Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _shieldController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    _networkAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _networkController, curve: Curves.linear),
    );

    _cardAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.elasticOut),
    );

    _securityAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _securityController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _nodeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _nodeController, curve: Curves.linear),
    );

    _shieldAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shieldController, curve: Curves.easeOutBack),
    );

    _cardController.forward();
    _shieldController.forward();
  }

  Future<void> _initializeWallet() async {
    try {
      await _walletService.initialize();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar("Failed to initialize wallet: $e");
      }
    }
  }


  Future<void> _updateWalletData() async {
    print("🔄 Updating wallet data...");

    if (!_walletService.isInitialized || _isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final balance = await _walletService.getBalance();
      if (mounted) {
        setState(() {
          _ethBalance = balance;
          _walletAddress = _walletService.walletAddress;
          _lastRefresh = DateTime.now();
          _isRefreshing = false;
          // Update network stats
          _activeNodes = 8 + Random().nextInt(5);
          _networkStrength = 0.85 + Random().nextDouble() * 0.15;
        });
        print("Wallet data updated! Balance: $balance");
      }
    } catch (e) {
      print("Error updating wallet data: $e");
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _walletService.removeListener(_onWalletStateChanged);
    _networkController.dispose();
    _cardController.dispose();
    _securityController.dispose();
    _pulseController.dispose();
    _nodeController.dispose();
    _shieldController.dispose();
    super.dispose();
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLoading = _walletService.isInitializing ||
        (!_walletService.isInitialized && !_walletService.isInitializing);

    return Scaffold(
      backgroundColor: Color(0xFF0A0B14),
      body: Stack(
        children: [
          // Blockchain network background
          _buildBlockchainNetworkBackground(),

          // Gradient overlay for better readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0A0B14).withOpacity(0.7),
                  Color(0xFF0A0B14).withOpacity(0.9),
                ],
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Fixed header
                _buildEnhancedHeader(isLoading),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        _buildPremiumBalanceCard(isLoading),
                        _buildNetworkStats(),
                        _buildSecurityBadge(),
                        _buildActionButtons(),
                        SizedBox(height: 16),
                        _buildAssetsSection(),
                        SizedBox(height: 70), // Space for bottom navigation
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBlockchainNetworkBackground() {
    return AnimatedBuilder(
      animation: _networkAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: BlockchainNetworkPainter(
            nodes,
            connections,
            _networkAnimation.value,
          ),
        );
      },
    );
  }

  Widget _buildEnhancedHeader(bool isLoading) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _isSecure ? Color(0xFF4AE8AB) : Colors.orange,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isSecure ? Color(0xFF4AE8AB) : Colors.orange)
                              .withOpacity(0.8),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'CRYPTOFORT',
                    style: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: screenWidth * 0.03,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                isLoading
                    ? 'Initializing Secure Vault...'
                    : 'Professional Wallet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.055,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Row(
            children: [
              // _buildHeaderButton(
              //   icon: Icons.fingerprint_outlined,
              //   onTap: () {
              //     HapticFeedback.heavyImpact();
              //     _showQRScanner();
              //   },
              // ),
              SizedBox(width: 12),
              _buildHeaderButton(
                icon: Icons.refresh,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  if (_walletService.isInitialized && !_isRefreshing) {
                    _updateWalletData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Syncing with blockchain...'),
                        backgroundColor: Color(0xFF60A5FA),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        margin: EdgeInsets.all(16),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else if (!_walletService.isInitialized) {
                    _initializeWallet();
                  }
                },
                isLoading: _isRefreshing,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Color(0xFF1A1B26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Color(0xFF2D2E3F),
            width: 1,
          ),
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Color(0xFF4AE8AB),
                    strokeWidth: 2,
                  ),
                )
              : Icon(
                  icon,
                  color: Color(0xFF9CA3AF),
                  size: 20,
                ),
        ),
      ),
    );
  }

  Widget _buildPremiumBalanceCard(bool isLoading) {
    final screenWidth = MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _cardAnimation.value,
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05,
              vertical: 8,
            ),
            height: 180,
            child: Stack(
              children: [
                // Card background with subtle gradient
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1A1B26),
                        Color(0xFF252736),
                      ],
                    ),
                    border: Border.all(
                      color: Color(0xFF2D2E3F),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                ),

                // Blockchain pattern overlay
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: CardPatternPainter(_pulseAnimation.value),
                  ),
                ),

                // Content
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOTAL BALANCE',
                                style: TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 11,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              AnimatedSwitcher(
                                duration: Duration(milliseconds: 300),
                                child: _isBalanceVisible
                                    ? Row(
                                        key: ValueKey('visible'),
                                        crossAxisAlignment:
                                            CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(
                                            isLoading ? 'Loading...' : 'Ξ',
                                            style: TextStyle(
                                              color: Color(0xFF4AE8AB),
                                              fontSize: 24,
                                              fontWeight: FontWeight.w300,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            isLoading ? '' : _ethBalance,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 32,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        '••••••',
                                        key: ValueKey('hidden'),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 32,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 4,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isBalanceVisible = !_isBalanceVisible;
                              });
                              HapticFeedback.lightImpact();
                            },
                            child: Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Color(0xFF252736),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Color(0xFF2D2E3F),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                _isBalanceVisible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Color(0xFF9CA3AF),
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Wallet address
                      if (_walletAddress.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(
                                ClipboardData(text: _walletAddress));
                            HapticFeedback.mediumImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Address copied to clipboard'),
                                backgroundColor: Color(0xFF4AE8AB),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                margin: EdgeInsets.all(16),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Color(0xFF1A1B26),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Color(0xFF2D2E3F),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_outlined,
                                  color: Color(0xFF9CA3AF),
                                  size: 14,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  '${_walletAddress.substring(0, 6)}...${_walletAddress.substring(_walletAddress.length - 4)}',
                                  style: TextStyle(
                                    color: Color(0xFF9CA3AF),
                                    fontSize: 13,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(
                                  Icons.copy_outlined,
                                  color: Color(0xFF9CA3AF),
                                  size: 12,
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Network status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Color(0xFF4AE8AB).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Color(0xFF4AE8AB).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Color(0xFF4AE8AB),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Sepolia Testnet',
                                  style: TextStyle(
                                    color: Color(0xFF4AE8AB),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_lastRefresh != null)
                            Text(
                              'Updated ${_getTimeAgo(_lastRefresh!)}',
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNetworkStats() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.hub_outlined,
              label: 'Active Nodes',
              value: '$_activeNodes',
              color: Color(0xFF4AE8AB),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.speed,
              label: 'Network Strength',
              value: '${(_networkStrength * 100).toInt()}%',
              color: Color(0xFF60A5FA),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.lock_outline,
              label: 'Encryption',
              value: '256-bit',
              color: Color(0xFFF59E0B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Color(0xFF1A1B26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xFF2D2E3F),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 18,
          ),
          SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityBadge() {
    return AnimatedBuilder(
      animation: _shieldAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _shieldAnimation.value,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1A1B26),
                  Color(0xFF252736),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isSecure
                    ? Color(0xFF4AE8AB).withOpacity(0.3)
                    : Colors.orange.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _securityAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _securityAnimation.value,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            color:
                                _isSecure ? Color(0xFF4AE8AB) : Colors.orange,
                            size: 32,
                          ),
                          Icon(
                            Icons.check,
                            color:
                                _isSecure ? Color(0xFF4AE8AB) : Colors.orange,
                            size: 16,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Security Status: $_securityLevel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'End-to-end encryption active',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Color(0xFF2D2E3F),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _isSecure ? 1.0 : 0.3,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _isSecure ? Color(0xFF4AE8AB) : Colors.orange,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isEnabled = _walletService.isInitialized;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _buildActionButton(
              label: 'Send',
              icon: Icons.arrow_upward,
              color: Color(0xFF4AE8AB),
              isEnabled: isEnabled,
              onTap: isEnabled ? () => _showSendDialog() : null,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              label: 'Receive',
              icon: Icons.arrow_downward,
              color: Color(0xFF60A5FA),
              isEnabled: isEnabled,
              onTap: isEnabled ? () => _showReceiveDialog() : null,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              label: 'Buy',
              icon: Icons.add,
              color: Color(0xFFF59E0B),
              isEnabled: isEnabled,
              onTap: isEnabled ? () => _showBuyDialog() : null,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              label: 'Swap',
              icon: Icons.swap_horiz,
              color: Color(0xFFA78BFA),
              isEnabled: isEnabled,
              onTap: isEnabled ? () => _showSwapDialog() : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isEnabled,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: isEnabled
          ? () {
              HapticFeedback.mediumImpact();
              onTap?.call();
            }
          : null,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        height: 60,
        decoration: BoxDecoration(
          color: isEnabled ? Color(0xFF1A1B26) : Color(0xFF0F1018),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isEnabled ? color.withOpacity(0.3) : Color(0xFF2D2E3F),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isEnabled ? color : Color(0xFF4B5563),
              size: 22,
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isEnabled ? Colors.white : Color(0xFF4B5563),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetsSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Color(0xFF0F1018),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Color(0xFF2D2E3F),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Assets',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '24h',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          // Asset items
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildAssetItem(
                  symbol: 'ETH',
                  name: 'Ethereum',
                  amount: _ethBalance,
                  icon: 'Ξ',
                  color: Color(0xFF627EEA),
                  change: '+2.34%',
                  isPositive: true,
                ),
                // Add more assets here if needed
                SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetItem({
    required String symbol,
    required String name,
    required String amount,
    required String icon,
    required Color color,
    required String change,
    required bool isPositive,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                icon,
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Wrap(
                  spacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '$amount $symbol',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                    if (_walletService.isInitialized)
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Color(0xFF4AE8AB).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Verified',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF4AE8AB),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isPositive
                  ? Color(0xFF4AE8AB).withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              change,
              style: TextStyle(
                fontSize: 12,
                color: isPositive ? Color(0xFF4AE8AB) : Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF0F1018),
        border: Border(
          top: BorderSide(
            color: Color(0xFF2D2E3F),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Container(
          height: 60,
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.account_balance_wallet_outlined, 'Wallet', 0),
              _buildNavItem(Icons.explore_outlined, 'Explore', 1),
              _buildNavItem(Icons.swap_horiz_outlined, 'Exchange', 2),
              _buildNavItem(Icons.settings_outlined, 'Settings', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();

        // If Settings is tapped → Only open page
        if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SecuritySettingsPage(walletService: _walletService),
            ),
          );
          return; //  STOP! Do not run setState!
        }

        //  Only update index for pages that stay inside Home
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Color(0xFF4AE8AB) : Color(0xFF6B7280),
              size: 22,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Color(0xFF4AE8AB) : Color(0xFF6B7280),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBuyDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Buy feature coming soon'),
        backgroundColor: Color(0xFFF59E0B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showSwapDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Swap feature coming soon'),
        backgroundColor: Color(0xFFA78BFA),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

// Network visualization classes
class NetworkNode {
  final double x;
  final double y;
  final double size;
  final bool isActive;
  final double pulseDelay;

  NetworkNode({
    required this.x,
    required this.y,
    required this.size,
    required this.isActive,
    required this.pulseDelay,
  });
}

class NodeConnection {
  final int startNode;
  final int endNode;
  final double strength;

  NodeConnection({
    required this.startNode,
    required this.endNode,
    required this.strength,
  });
}

// Custom painter for blockchain network visualization
class BlockchainNetworkPainter extends CustomPainter {
  final List<NetworkNode> nodes;
  final List<NodeConnection> connections;
  final double animationValue;

  BlockchainNetworkPainter(this.nodes, this.connections, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw connections
    final connectionPaint = Paint()
      ..color = Color(0xFF4AE8AB).withOpacity(0.1)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (var connection in connections) {
      final start = nodes[connection.startNode];
      final end = nodes[connection.endNode];

      final opacity =
          (sin(animationValue * 2 * pi + connection.strength * pi) + 1) / 2;
      connectionPaint.color =
          Color(0xFF4AE8AB).withOpacity(0.05 + opacity * 0.1);

      canvas.drawLine(
        Offset(start.x * size.width, start.y * size.height),
        Offset(end.x * size.width, end.y * size.height),
        connectionPaint,
      );
    }

    // Draw nodes
    for (var node in nodes) {
      final center = Offset(node.x * size.width, node.y * size.height);

      // Node glow effect
      final glowPaint = Paint()
        ..color = (node.isActive ? Color(0xFF4AE8AB) : Color(0xFF6B7280))
            .withOpacity(0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10);

      canvas.drawCircle(center, node.size + 2, glowPaint);

      // Node itself
      final nodePaint = Paint()
        ..color = node.isActive ? Color(0xFF4AE8AB) : Color(0xFF6B7280)
        ..style = PaintingStyle.fill;

      // Animated pulse effect
      final pulsePhase = (animationValue + node.pulseDelay) % 1.0;
      final pulseScale = 1 + sin(pulsePhase * 2 * pi) * 0.2;

      canvas.drawCircle(center, node.size * pulseScale, nodePaint);

      // Inner dot
      final innerPaint = Paint()
        ..color = Color(0xFF0A0B14)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, node.size * 0.5 * pulseScale, innerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Card pattern painter
class CardPatternPainter extends CustomPainter {
  final double animationValue;

  CardPatternPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF4AE8AB).withOpacity(0.03)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw hexagon grid pattern
    final hexSize = 30.0;
    final rows = (size.height / hexSize).ceil() + 1;
    final cols = (size.width / hexSize).ceil() + 1;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final x = col * hexSize * 1.5;
        final y = row * hexSize * sqrt(3) + (col % 2) * hexSize * sqrt(3) / 2;

        if (x < size.width + hexSize && y < size.height + hexSize) {
          _drawHexagon(canvas, Offset(x, y), hexSize * 0.5, paint);
        }
      }
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * pi / 180;
      final x = center.dx + size * cos(angle);
      final y = center.dy + size * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
