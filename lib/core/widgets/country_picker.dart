import 'package:flutter/material.dart';
import 'package:mymink/core/constants/contries_list.dart';

class CountryPicker {
  static void show(BuildContext context, Function(String, String) onSelected) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        String searchQuery = '';
        List<Map<String, String>> filteredList = countryList;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Line
                    Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Search Field with Glassmorphism Style
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.5),
                            blurRadius: 30,
                            offset: const Offset(-10, -10),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 30,
                            offset: const Offset(10, 10),
                          ),
                        ],
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search country',
                          prefixIcon:
                              Icon(Icons.search, color: Colors.grey[600]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 15, horizontal: 10),
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value.toLowerCase();
                            filteredList = countryList
                                .where((country) =>
                                    country['name']!
                                        .toLowerCase()
                                        .contains(searchQuery) ||
                                    country['dial_code']!.contains(searchQuery))
                                .toList();
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Country List
                    Expanded(
                      child: ListView.separated(
                        itemCount: filteredList.length,
                        separatorBuilder: (_, __) =>
                            Divider(color: Colors.grey[200]),
                        itemBuilder: (BuildContext context, int index) {
                          final country = filteredList[index];
                          return ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 10),
                            leading: Text(
                              country['flag']!,
                              style: const TextStyle(fontSize: 28),
                            ),
                            title: Text(
                              country['name']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              country['dial_code']!,
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey[400],
                            ),
                            onTap: () {
                              onSelected(
                                  country['dial_code']!, country['flag']!);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
