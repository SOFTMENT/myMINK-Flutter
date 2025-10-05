import 'package:flutter/material.dart';

import 'package:mymink/gen/assets.gen.dart';

class TodoIntroSheet extends StatelessWidget {
  const TodoIntroSheet({super.key, required this.onPressed});
  final Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Assets.images.colorfuldesign
                    .image(height: 100, width: 150, fit: BoxFit.fill),
              ),
              const SizedBox(height: 100), // Optional spacing buffer
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 30),
                  child: Assets.images.logo.image(width: 194, height: 74),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: const Text(
              'A To do is a digital task manager that allows user to organise, track and prioritise their daily tasks and reminders in a simple, user-friendly interface. It helps users stay focused and efficient by managing their personal and professional responsibilities in one accessible location',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(bottom: 32, left: 25, right: 25),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  onPressed();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  'Get Started',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
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
