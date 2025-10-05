import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/widgets/dismiss_keyboard_ontap.dart';
import 'package:mymink/core/widgets/progress_hud.dart';
import 'package:mymink/features/horoscope/data/models/horoscope_model.dart';
import 'package:mymink/features/horoscope/widgets/horoscope_item.dart';

class DailyHoroscopePage extends StatefulWidget {
  @override
  State<DailyHoroscopePage> createState() => _DailyHoroscopePageState();
}

class _DailyHoroscopePageState extends State<DailyHoroscopePage> {
  HoroscopeModel? horoscopeModel;
  bool _isLoading = true;

  Future<HoroscopeModel?> getHoroscopeModel() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('Horoscopes')
          .doc('daily')
          .get();

      if (snapshot.exists) {
        return HoroscopeModel.fromJson(snapshot.data()!);
      } else {
        throw Exception("Document does not exist.");
      }
    } catch (e) {
  
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    updateHoroscopeModel();
  }

  void updateHoroscopeModel() async {
    horoscopeModel = await getHoroscopeModel();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          DismissKeyboardOnTap(
            child: Column(
              children: [
                // White top section
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
                                    'Daily Horoscopes',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textBlack,
                                    ),
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
                        ),
                      ],
                    ),
                  ),
                ),

                // Centered Horoscope Grid
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 25, vertical: 20),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildRow([
                              HoroscopeItem(
                                imagePath: 'assets/images/horoscope/aries.png',
                                height: 96,
                                label: 'Aries',
                                result: horoscopeModel?.aries ?? '',
                              ),
                              HoroscopeItem(
                                imagePath: 'assets/images/horoscope/taurus.png',
                                height: 100,
                                label: 'Taurus',
                                result: horoscopeModel?.taurus ?? '',
                              ),
                              HoroscopeItem(
                                imagePath: 'assets/images/horoscope/gemini.png',
                                height: 117,
                                label: 'Gemini',
                                result: horoscopeModel?.gemini ?? '',
                              ),
                            ]),
                            const SizedBox(height: 20),
                            _buildRow([
                              HoroscopeItem(
                                imagePath: 'assets/images/horoscope/cancer.png',
                                height: 100,
                                label: 'Cancer',
                                result: horoscopeModel?.cancer ?? '',
                              ),
                              HoroscopeItem(
                                imagePath: 'assets/images/horoscope/leo.png',
                                height: 100,
                                label: 'Leo',
                                result: horoscopeModel?.leo ?? '',
                              ),
                              HoroscopeItem(
                                imagePath: 'assets/images/horoscope/virgo.png',
                                height: 100,
                                label: 'Virgo',
                                result: horoscopeModel?.virgo ?? '',
                              ),
                            ]),
                            const SizedBox(height: 20),
                            _buildRow([
                              HoroscopeItem(
                                imagePath: 'assets/images/horoscope/libra.png',
                                height: 100,
                                label: 'Libra',
                                result: horoscopeModel?.libra ?? '',
                              ),
                              HoroscopeItem(
                                imagePath:
                                    'assets/images/horoscope/scorpio.png',
                                height: 100,
                                label: 'Scorpio',
                                result: horoscopeModel?.aries ?? '',
                              ),
                              HoroscopeItem(
                                imagePath:
                                    'assets/images/horoscope/sagitarius.png',
                                height: 100,
                                label: 'Sagittarius',
                                result: horoscopeModel?.sagittarius ?? '',
                              ),
                            ]),
                            const SizedBox(height: 20),
                            _buildRow([
                              HoroscopeItem(
                                imagePath:
                                    'assets/images/horoscope/capricornus.png',
                                height: 100,
                                label: 'Capricornus',
                                result: horoscopeModel?.capricorn ?? '',
                              ),
                              HoroscopeItem(
                                imagePath:
                                    'assets/images/horoscope/aquarius.png',
                                height: 100,
                                label: 'Aquarius',
                                result: horoscopeModel?.aquarius ?? '',
                              ),
                              HoroscopeItem(
                                imagePath: 'assets/images/horoscope/pisces.png',
                                height: 100,
                                label: 'Pisces',
                                result: horoscopeModel?.pisces ?? '',
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Center(
              child: ProgressHud(
                message: 'Loading...',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRow(List<Widget> items) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items,
    );
  }
}
