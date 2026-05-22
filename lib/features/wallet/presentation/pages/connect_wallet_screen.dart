import 'package:flutter/material.dart';
import 'package:expense_tracker/features/wallet/presentation/widgets/connect_wallet_helper.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';

class ConnectWalletScreen extends StatefulWidget {
  const ConnectWalletScreen({super.key});

  @override
  State<ConnectWalletScreen> createState() => _ConnectWalletScreenState();
}

class _ConnectWalletScreenState extends State<ConnectWalletScreen> {
  int _selectedTabIndex = 1;
  String _selectedAccount = "Bank Link";

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
                        ConnectWalletHelper.buildCardsTab(context)
                      else
                        ConnectWalletHelper.buildAccountsTab(
                          context: context,
                          selectedAccount: _selectedAccount,
                          onAccountSelected: (account) {
                            setState(() {
                              _selectedAccount = account;
                            });
                          },
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
