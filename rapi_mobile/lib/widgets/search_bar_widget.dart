import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({
    super.key,
    required this.hintText,
    required this.textController,
    required this.onChanged,
  });

  final String hintText;
  final TextEditingController textController;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Theme-aware colors
    final backgroundColor = isDark
        ? Colors.grey[900]!.withOpacity(0.3)
        : Colors.grey[100]!.withOpacity(0.5);

    final outlineColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    final iconColor = isDark ? Colors.grey[300] : Colors.grey[600];

    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(50.0),
        border: Border.all(color: outlineColor, width: 1.5),
      ),
      child: TextField(
        controller: textController,
        onChanged: onChanged,
        style: TextStyle(color: theme.textTheme.bodyLarge?.color),
        decoration: InputDecoration(
          icon: Icon(Icons.search, color: iconColor),
          hintText: hintText,
          hintStyle: TextStyle(color: theme.hintColor),
          border: InputBorder.none,
          suffixIcon: textController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: iconColor),
                  onPressed: () {
                    textController.clear();
                    onChanged('');
                  },
                )
              : null,
        ),
      ),
    );
  }
}
