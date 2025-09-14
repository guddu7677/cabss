import 'package:flutter/material.dart';
import 'package:our_cabss/theme_provider/theme_provider.dart';

class SearchPlacesScreen extends StatefulWidget {
  const SearchPlacesScreen({super.key});

  @override
  State<SearchPlacesScreen> createState() => _SearchPlacesScreenState();
}

class _SearchPlacesScreenState extends State<SearchPlacesScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.primaryColor,
          title: Text(
            "Search & Set Drop Off location",
            style: TextStyle(
              color: theme.appBarTheme.foregroundColor ?? 
                     (isDark ? Colors.white : Colors.white),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevation: 0,
          leading: GestureDetector(
            child: Icon(
              Icons.arrow_back,
              color: theme.appBarTheme.foregroundColor ?? 
                     (isDark ? Colors.white : Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black54 : Colors.grey,
                    blurRadius: 6,
                    spreadRadius: 0.5,
                    offset: const Offset(0.7, 0.7),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
