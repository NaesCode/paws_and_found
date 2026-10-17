import 'package:flutter/material.dart';

class ProfileIcon extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isActive;

  const ProfileIcon({
    super.key,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF374151); // Dark slate color from reference

    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: isActive ? activeColor : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.person_outline,
              color: isActive ? Colors.white : Colors.black87,
              size: 24,
            ),
          ),
          SizedBox(
            height: 12,
            child: isActive
                ? Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: activeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

