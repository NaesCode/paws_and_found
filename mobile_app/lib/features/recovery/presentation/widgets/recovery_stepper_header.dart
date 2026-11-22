import 'package:flutter/material.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';

class RecoveryStepperHeader extends StatelessWidget {
  final int currentStage;
  final bool isCompleted;
  final ValueChanged<int> onStageTap;

  const RecoveryStepperHeader({
    super.key,
    required this.currentStage,
    required this.isCompleted,
    required this.onStageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        children: [
          _buildStep(step: 1, label: 'Agreement'),
          _buildConnector(active: currentStage > 1 || isCompleted),
          _buildStep(step: 2, label: 'Verification'),
          _buildConnector(active: currentStage > 2 || isCompleted),
          _buildStep(step: 3, label: 'Retrieval'),
        ],
      ),
    );
  }

  Widget _buildStep({required int step, required String label}) {
    final bool isDone = isCompleted || step < currentStage;
    final bool isActive = !isCompleted && step == currentStage;
    final bool isLocked = !isCompleted && step > currentStage;

    Color circleColor = AppColors.background2;
    Color contentColor = AppColors.text3;

    if (isDone) {
      circleColor = AppColors.primary;
      contentColor = Colors.white;
    } else if (isActive) {
      circleColor = AppColors.accentOrange;
      contentColor = Colors.white;
    }

    return GestureDetector(
      onTap: () => onStageTap(step),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: isDone
                ? Icon(Icons.check_rounded, size: 18, color: contentColor)
                : isLocked
                    ? Icon(Icons.lock_outline_rounded, size: 16, color: contentColor)
                    : Text(
                        '$step',
                        style: TextStyle(
                          color: contentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: (isActive || isDone) ? FontWeight.bold : FontWeight.w500,
              color: isActive
                  ? AppColors.accentOrange
                  : (isDone ? AppColors.primary : AppColors.text3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnector({required bool active}) {
    return Expanded(
      child: Container(
        height: 2.5,
        margin: const EdgeInsets.only(bottom: 18, left: 6, right: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.background2,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}