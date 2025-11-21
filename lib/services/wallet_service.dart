// lib/services/wallet_service.dart

import 'dart:math';
import 'dart:ui';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:bip39/bip39.dart' as bip39;

class WalletService {
  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;
  WalletService._internal();

  Web3Client? _client;
  Credentials? _credentials;
  final _storage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  static const String _rpcUrl = "INFURA_API_KEY"; // Replace with your Sepolia RPC URL

  EthereumAddress? _walletAddress;
  bool _isInitialized = false;
  bool _isInitializing = false;
  String? _mnemonic;

  final List<VoidCallback> _listeners = [];

  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;
  String get walletAddress => _walletAddress?.hex ?? "";
  String? get mnemonic => _mnemonic;

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  // Check if biometric authentication is available
  Future<bool> canAuthenticateWithBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      print("Error checking biometrics: $e");
      return false;
    }
  }

  // Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print("Error getting available biometrics: $e");
      return [];
    }
  }

  // Authenticate with biometrics
  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access your wallet',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (e) {
      print("Error authenticating: $e");
      return false;
    }
  }

  // Check if wallet exists
  Future<bool> walletExists() async {
    final privateKeyHex = await _storage.read(key: 'wallet_private_key');
    return privateKeyHex != null;
  }

  // Check if biometric is enabled
  Future<bool> isBiometricEnabled() async {
    final enabled = await _storage.read(key: 'biometric_enabled');
    return enabled == 'true';
  }

  // Enable/Disable biometric
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: 'biometric_enabled', value: enabled.toString());
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    if (_isInitializing) return;

    _isInitializing = true;
    _notifyListeners();

    try {
      // Check if biometric is enabled
      final biometricEnabled = await isBiometricEnabled();

      // If biometric is enabled, require authentication
      if (biometricEnabled) {
        final authenticated = await authenticateWithBiometrics();
        if (!authenticated) {
          _isInitializing = false;
          _notifyListeners();
          throw Exception("Authentication failed");
        }
      }

      _client = Web3Client(_rpcUrl, Client());
      await _loadOrCreateWallet();
      _isInitialized = true;
      _isInitializing = false;
      _notifyListeners();
    } catch (e) {
      _isInitializing = false;
      _notifyListeners();
      print("Wallet initialization failed: $e");
      throw Exception("Failed to initialize wallet: $e");
    }
  }

  Future<void> _loadOrCreateWallet() async {
    final privateKeyHex = await _storage.read(key: 'wallet_private_key');
    final storedMnemonic = await _storage.read(key: 'wallet_mnemonic');

    if (privateKeyHex != null) {
      _credentials = EthPrivateKey.fromHex(privateKeyHex);
      _mnemonic = storedMnemonic;
    } else {
      // Generate new mnemonic (12 words)
      _mnemonic = bip39.generateMnemonic();

      // Derive private key from mnemonic
      final seed = bip39.mnemonicToSeed(_mnemonic!);
      final privateKey = seed.sublist(0, 32);

      _credentials = EthPrivateKey(privateKey);

      final ethPrivateKey = _credentials as EthPrivateKey;
      await _storage.write(
          key: 'wallet_private_key',
          value:
              ethPrivateKey.privateKeyInt.toRadixString(16).padLeft(64, '0'));

      // Store mnemonic
      await _storage.write(key: 'wallet_mnemonic', value: _mnemonic);

      // Mark that backup is needed
      await _storage.write(key: 'backup_completed', value: 'false');
    }

    _walletAddress = _credentials!.address;
    print("Wallet Address: ${_walletAddress!.hex}");
  }

  // Check if backup is completed
  Future<bool> isBackupCompleted() async {
    final backup = await _storage.read(key: 'backup_completed');
    return backup == 'true';
  }

  // Mark backup as completed
  Future<void> markBackupCompleted() async {
    await _storage.write(key: 'backup_completed', value: 'true');
  }

  // Recover wallet from mnemonic
  Future<bool> recoverFromMnemonic(String mnemonic) async {
    try {
      // Validate mnemonic
      if (!bip39.validateMnemonic(mnemonic)) {
        throw Exception("Invalid mnemonic phrase");
      }

      // Derive private key from mnemonic
      final seed = bip39.mnemonicToSeed(mnemonic);
      final privateKey = seed.sublist(0, 32);

      _credentials = EthPrivateKey(privateKey);
      _mnemonic = mnemonic;

      final ethPrivateKey = _credentials as EthPrivateKey;
      await _storage.write(
          key: 'wallet_private_key',
          value:
              ethPrivateKey.privateKeyInt.toRadixString(16).padLeft(64, '0'));

      await _storage.write(key: 'wallet_mnemonic', value: mnemonic);
      await _storage.write(key: 'backup_completed', value: 'true');

      _walletAddress = _credentials!.address;
      _isInitialized = true;
      _notifyListeners();

      return true;
    } catch (e) {
      print("Recovery failed: $e");
      return false;
    }
  }

  Future<String> getBalance() async {
    if (!_isInitialized || _client == null || _walletAddress == null) {
      return "0.0000";
    }

    try {
      final balance = await _client!.getBalance(_walletAddress!);
      return balance.getValueInUnit(EtherUnit.ether).toStringAsFixed(4);
    } catch (e) {
      print("Error getting balance: $e");
      return "0.0000";
    }
  }

  Future<TransactionReceipt?> getTransactionReceipt(String txHash) async {
    if (!_isInitialized || _client == null) {
      print("WALLET_SERVICE: Cannot check receipt: Wallet not initialized");
      return null;
    }

    try {
      print("WALLET_SERVICE: Fetching receipt for: $txHash");
      final receipt = await _client!.getTransactionReceipt(txHash);

      if (receipt != null) {
        print(
            "WALLET_SERVICE: Receipt found! Block: ${receipt.blockNumber}, Status: ${receipt.status}");
      } else {
        print(
            "WALLET_SERVICE: Receipt not available yet (transaction pending)");
      }

      return receipt;
    } catch (e) {
      print(" WALLET_SERVICE: Error getting transaction receipt: $e");
      return null;
    }
  }

  Future<bool> waitForTransaction(String txHash,
      {Duration timeout = const Duration(minutes: 2)}) async {
    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < timeout) {
      final receipt = await getTransactionReceipt(txHash);
      if (receipt != null) {
        return receipt.status ?? false;
      }
      await Future.delayed(Duration(seconds: 2));
    }

    return false;
  }

  Future<String> sendEth({
    required String toAddress,
    required double amount,
  }) async {
    print(
        "WALLET_SERVICE: sendEth() called with amount: $amount ETH to: $toAddress");

    if (!_isInitialized || _client == null || _credentials == null) {
      print("WALLET_SERVICE: Wallet not initialized");
      throw Exception("Wallet not initialized");
    }

    try {
      print("WALLET_SERVICE: Parsing recipient address");
      final recipient = EthereumAddress.fromHex(toAddress);

      print("WALLET_SERVICE: Checking balance");
      final balance = await _client!.getBalance(_walletAddress!);
      final balanceInEther = balance.getValueInUnit(EtherUnit.ether);
      print("WALLET_SERVICE: Current balance: $balanceInEther ETH");

      final maxSendable = balanceInEther - 0.01;
      if (amount > maxSendable) {
        print("WALLET_SERVICE: Insufficient balance");
        throw Exception(
            "Insufficient balance. Max sendable: ${maxSendable.toStringAsFixed(4)} ETH (reserving 0.01 ETH for gas)");
      }

      print("WALLET_SERVICE: Converting amount to Wei");
      final BigInt amountInWei = BigInt.from(amount * 1e18);
      final etherAmount = EtherAmount.inWei(amountInWei);

      print("WALLET_SERVICE: Getting gas price");
      final gasPrice = await _client!.getGasPrice();
      const gasLimit = 21000;
      print("WALLET_SERVICE: Gas price: $gasPrice, Gas limit: $gasLimit");

      print("WALLET_SERVICE: Creating transaction");
      final transaction = Transaction(
        to: recipient,
        gasPrice: gasPrice,
        maxGas: gasLimit,
        value: etherAmount,
      );

      print("WALLET_SERVICE: Sending transaction to blockchain...");
      final txHash = await _client!.sendTransaction(
        _credentials!,
        transaction,
        chainId: 11155111,
      );

      print("WALLET_SERVICE: Transaction sent successfully! Hash: $txHash");
      print("WALLET_SERVICE: About to return txHash to caller");
      return txHash;
    } catch (e, stackTrace) {
      print("WALLET_SERVICE: Send transaction error: $e");
      print("WALLET_SERVICE: Stack trace: $stackTrace");
      throw Exception("Transaction failed: ${e.toString()}");
    }
  }

  void dispose() {
    _client?.dispose();
    _listeners.clear();
  }
}
