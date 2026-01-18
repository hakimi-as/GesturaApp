import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/progress_provider.dart';

class WelcomeCard extends StatelessWidget {
  const WelcomeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (context, progressProvider, child) {
        final goals = progressProvider.dailyGoals;
        final completedGoals = progressProvider.completedGoals;
        final totalGoals = progressProvider.totalGoals;
        final progress = totalGoals > 0 ? completedGoals / totalGoals : 0.0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Daily Goal',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$completedGoals / $totalGoals completed',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        '🎯',
                        style: TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 16),

              // Goal Items
              ...goals.take(2).map((goal) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      goal.isCompleted
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: goal.isCompleted
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        goal.title,
                        style: TextStyle(
                          color: goal.isCompleted
                              ? Colors.white
                              : Colors.white.withOpacity(0.7),
                          fontSize: 13,
                          decoration: goal.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    Text(
                      '+${goal.xpReward} XP',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        );
      },
    );
  }
}