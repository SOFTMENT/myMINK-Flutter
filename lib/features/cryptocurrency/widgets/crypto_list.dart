import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mymink/features/cryptocurrency/data/models/crypto_model.dart';

class CryptoList extends StatelessWidget {
  final List<CryptoModel> cryptoList;

  const CryptoList({super.key, required this.cryptoList});
  String addCommaInLargeNumber(double number, {int fractionDigits = 10}) {
    final formatter = NumberFormat.decimalPattern()
      ..maximumFractionDigits = fractionDigits;

    return formatter.format(number);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.all(0),
      itemCount: cryptoList.length,
      itemBuilder: (context, index) {
        final crypto = cryptoList[index];
        final priceChange = crypto.priceChangePercentage24H;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.network(
                      crypto.image,
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 12),

                    // Name & Symbol
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          crypto.symbol.toUpperCase(),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '1 ${crypto.symbol.toUpperCase()}',
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                // Icon

                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "\$${addCommaInLargeNumber(crypto.currentPrice)}",
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),

                // Price Change %
                Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          priceChange >= 0
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down,
                          color: priceChange >= 0 ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        Text(
                          "${priceChange.toStringAsFixed(1)}%",
                          style: TextStyle(
                            color: priceChange >= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Total Value
                Text(
                  "\$${addCommaInLargeNumber(double.tryParse(crypto.marketCap.toStringAsFixed(0))!)}",
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
