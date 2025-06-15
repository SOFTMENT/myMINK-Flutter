import 'package:flutter/material.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/widgets/custom_app_bar.dart';

class LibraryAToZPage extends StatelessWidget {
  const LibraryAToZPage({super.key});

  @override
  Widget build(BuildContext context) {
    final letters = List.generate(26, (i) => String.fromCharCode(65 + i));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          CustomAppBar(title: 'A to Z'),
          Expanded(
            child: Center(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 25, vertical: 80),
                child: GridView.count(
                  crossAxisCount: 6,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (final letter in letters)
                      GestureDetector(
                        onTap: () {
                          // return the tapped letter to the caller
                          Navigator.of(context).pop(letter);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            letter,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
