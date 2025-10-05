import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/services/crypto_services.dart';

import 'package:mymink/core/widgets/dismiss_keyboard_ontap.dart';
import 'package:mymink/core/widgets/search_bar_with_button.dart';

import 'package:mymink/features/cryptocurrency/data/models/crypto_model.dart';
import 'package:mymink/features/cryptocurrency/widgets/crypto_list.dart';

class CryptocurrencyPage extends StatefulWidget {
  @override
  State<CryptocurrencyPage> createState() => _CryptocurrencyPageState();
}

class _CryptocurrencyPageState extends State<CryptocurrencyPage> {
  final TextEditingController _searchController = TextEditingController();

  List<CryptoModel> fullList = [];
  List<CryptoModel> filteredList = [];
  String selectedCurrency = 'AUD ⬇️';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    updateUI();
  }

  void updateUI() async {
    fullList = await CryptoServices.getAllCryptoAssets(
        selectedCurrency.split(' ').first.toLowerCase());
    filteredList = List.from(fullList);
    setState(() {});
  }

  void _onSearchChanged() {
    String searchText = _searchController.text.toLowerCase();

    if (searchText.isEmpty) {
      filteredList = List.from(fullList);
    } else {
      filteredList = fullList.where((crypto) {
        final nameMatch = crypto.name.toLowerCase().contains(searchText);
        final symbolMatch = crypto.symbol.toLowerCase().contains(searchText);
        return nameMatch || symbolMatch;
      }).toList();
    }

    setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Grey background (below tab)
      body: DismissKeyboardOnTap(
        child: Column(
          children: [
            // White top section (SafeArea + Headers + Search)
            Container(
              color: Colors.white,
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Top Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withAlpha(80),
                                    spreadRadius: 1,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_back_outlined,
                                color: Colors.black,
                                size: 18,
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Center(
                              child: Text(
                                'Cryptocurrency',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textBlack),
                              ),
                            ),
                          ),
                          const SizedBox(width: 44),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(
                      color: Color.fromARGB(49, 158, 158, 158),
                      height: 0.3,
                    )
                  ],
                ),
              ),
            ),

            // Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Coin',
                    style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textBlack,
                        fontWeight: FontWeight.bold),
                  ),
                  Column(
                    children: [
                      const Text(
                        'Price',
                        style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textBlack,
                            fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          const SizedBox(width: 7),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              setState(() {
                                selectedCurrency = value;
                                updateUI(); // fetch data again with new currency
                              });
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                  value: 'AUD ⬇️', child: Text('AUD')),
                              const PopupMenuItem(
                                  value: 'USD ⬇️', child: Text('USD')),
                            ],
                            child: Row(
                              children: [
                                Text(
                                  selectedCurrency,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textDarkGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                  const Text(
                    '24H',
                    style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textBlack,
                        fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Market Cap',
                    style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textBlack,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // Search Field
            SearchBarWithButton(
                hintText: 'Search',
                controller: _searchController,
                onPressed: () {}),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 25, vertical: 0),
                child: CryptoList(cryptoList: filteredList),
              ),
            ),
            // Expanded Grey Background List Area
          ],
        ),
      ),
    );
  }
}
