import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

class CategoryFilter extends StatelessWidget {
  final Function(String) onCategorySelected;
  final String selectedCategory;

  const CategoryFilter({
    super.key,
    required this.onCategorySelected,
    required this.selectedCategory,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: AppConstants.eventCategories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            // "Tất cả" option
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: const Text('Tất cả'),
                selected: selectedCategory.isEmpty,
                onSelected: (selected) {
                  onCategorySelected('');
                },
                selectedColor: AppColors.primaryLight,
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: selectedCategory.isEmpty
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontWeight: selectedCategory.isEmpty
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            );
          }

          final category = AppConstants.eventCategories[index - 1];
          final isSelected = selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                onCategorySelected(selected ? category : '');
              },
              selectedColor: _getCategoryColor(category).withOpacity(0.2),
              checkmarkColor: _getCategoryColor(category),
              labelStyle: TextStyle(
                color: isSelected
                    ? _getCategoryColor(category)
                    : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Technology':
        return AppColors.academicColor;
      case 'Sports':
        return AppColors.sportsColor;
      case 'Culture':
        return AppColors.cultureColor;
      default:
        return AppColors.otherColor;
    }
  }
}
