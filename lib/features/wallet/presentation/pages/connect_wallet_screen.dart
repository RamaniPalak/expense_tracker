import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/features/wallet/presentation/widgets/connect_wallet_helper.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';
import 'package:expense_tracker/core/di/injection_container.dart';

class ConnectWalletScreen extends StatefulWidget {
  const ConnectWalletScreen({super.key});

  @override
  State<ConnectWalletScreen> createState() => _ConnectWalletScreenState();
}

class _ConnectWalletScreenState extends State<ConnectWalletScreen> {
  int _selectedTabIndex = 0; // Default to Cards tab
  String _selectedAccount = "Bank Link";
  bool _isSaving = false;

  final TextEditingController _nameController =
      TextEditingController(text: "IRVAN MOSES");
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _cvcController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onFieldChanged);
    _numberController.addListener(_onFieldChanged);
    _expiryController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFieldChanged);
    _numberController.removeListener(_onFieldChanged);
    _expiryController.removeListener(_onFieldChanged);
    _nameController.dispose();
    _numberController.dispose();
    _cvcController.dispose();
    _expiryController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveCard() async {
    final name = _nameController.text.trim();
    final number = _numberController.text.replaceAll(RegExp(r'\s+'), '').trim();
    final cvc = _cvcController.text.trim();
    final expiry = _expiryController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the name on the card.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (number.length < 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please enter a valid card number (at least 12 digits).'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (cvc.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 3 or 4-digit CVC.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!RegExp(r'^\d{2}\/\d{2}$').hasMatch(expiry)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please enter expiration in MM/YY format (e.g. 12/28).'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final prefs = sl<SharedPreferences>();
      final existingCardsJson = prefs.getStringList('connected_cards') ?? [];

      final last4 =
          number.length >= 4 ? number.substring(number.length - 4) : number;
      final cardData = {
        'holderName': name,
        'last4': last4,
        'expiry': expiry,
        'connectedAt': DateTime.now().toIso8601String(),
      };

      existingCardsJson.add(jsonEncode(cardData));
      await prefs.setStringList('connected_cards', existingCardsJson);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Card ending in •••• $last4 linked successfully!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to save card: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _handleConnectAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 10),
            Text('$_selectedAccount Connected'),
          ],
        ),
        content: Text(
          'Your $_selectedAccount has been linked for wallet operations. Transactions will reflect seamlessly.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Done',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Scaffold(
      backgroundColor: c.background,
      body: Column(
        children: [
          ConnectWalletHelper.buildHeader(context),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -60),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: c.background,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    children: [
                      ConnectWalletHelper.buildTabSwitcher(
                        context: context,
                        selectedTabIndex: _selectedTabIndex,
                        onTabChanged: (index) {
                          setState(() {
                            _selectedTabIndex = index;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      if (_selectedTabIndex == 0)
                        ConnectWalletHelper.buildCardsTab(
                          context: context,
                          nameController: _nameController,
                          numberController: _numberController,
                          cvcController: _cvcController,
                          expiryController: _expiryController,
                          zipController: _zipController,
                          onSaveCard: _handleSaveCard,
                          isSaving: _isSaving,
                        )
                      else
                        ConnectWalletHelper.buildAccountsTab(
                          context: context,
                          selectedAccount: _selectedAccount,
                          onAccountSelected: (account) {
                            setState(() {
                              _selectedAccount = account;
                            });
                          },
                          onNext: _handleConnectAccount,
                        ),
                    ],
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
