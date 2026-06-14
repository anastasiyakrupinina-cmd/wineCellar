import 'package:flutter/material.dart';
import 'package:wine_cellar/core/colors/app_colors.dart';
import 'package:wine_cellar/core/style/app_text_style.dart';
import 'package:wine_cellar/feature/wine/data/models/wine_model.dart';

class PriceTile extends StatelessWidget {
  final WinePrice price;
  const PriceTile({super.key, required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBlue.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(price.merchant ?? 'Merchant', style: AppTextStyles.body),
          Text(
            '${price.price} ${price.currency}',
            style: AppTextStyles.h2.copyWith(color: AppColors.darkBlue, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class ScoreTile extends StatelessWidget {
  final WineScore score;
  const ScoreTile({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final displayScore = (score.scoreText?.isNotEmpty == true)
        ? score.scoreText!
        : score.score?.toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBlue.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          if (displayScore != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                displayScore,
                style: AppTextStyles.h2.copyWith(fontSize: 16, color: AppColors.darkBlue),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              score.reviewer.isNotEmpty ? score.reviewer : 'Unknown reviewer',
              style: AppTextStyles.body,
            ),
          ),
          if (score.reviewDate != null && score.reviewDate!.isNotEmpty)
            Text(
              score.reviewDate!,
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }
}
