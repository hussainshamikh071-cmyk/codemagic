import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final VoidCallback? onTap;
  final bool isLoading;

  const ProfileAvatar({
    Key? key,
    this.imageUrl,
    this.radius = 50,
    this.onTap,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Shimmer.fromColors(
        baseColor: Colors.white10,
        highlightColor: Colors.white24,
        child: CircleAvatar(radius: radius, backgroundColor: Colors.white),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: Colors.white10,
            backgroundImage: (imageUrl != null && imageUrl!.isNotEmpty)
                ? NetworkImage(imageUrl!)
                : null,
            child: (imageUrl == null || imageUrl!.isEmpty)
                ? Icon(Icons.person, size: radius, color: Colors.white38)
                : null,
          ),
          if (onTap != null)
            Positioned(
              bottom: 0,
              right: 0,
              child: CircleAvatar(
                radius: radius * 0.3,
                backgroundColor: Colors.redAccent,
                child: Icon(Icons.camera_alt, size: radius * 0.35, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
