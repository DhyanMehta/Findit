import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/user_provider.dart';

class ProfileAvatar extends StatelessWidget {
  final double radius;
  final bool showEditIcon;
  final VoidCallback? onTap;
  final String? imageUrl;
  final File? selectedImage; // Add support for File images

  const ProfileAvatar({
    Key? key,
    this.radius = 30,
    this.showEditIcon = false,
    this.onTap,
    this.imageUrl,
    this.selectedImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final avatarUrl = imageUrl ?? userProvider.avatarUrl;

        return GestureDetector(
          onTap: onTap,
          child: Stack(
            children: [
              Container(
                width: radius * 2,
                height: radius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade200,
                  border: Border.all(color: Colors.blue.shade200, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: selectedImage != null
                      ? Image.file(
                          selectedImage!,
                          width: radius * 2,
                          height: radius * 2,
                          fit: BoxFit.cover,
                        )
                      : avatarUrl?.isNotEmpty == true
                      ? Image.network(
                          avatarUrl!,
                          width: radius * 2,
                          height: radius * 2,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: radius * 2,
                              height: radius * 2,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey.shade200,
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.blue.shade400,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: radius * 2,
                              height: radius * 2,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey.shade200,
                              ),
                              child: Icon(
                                Icons.person,
                                size: radius * 0.8,
                                color: Colors.grey.shade400,
                              ),
                            );
                          },
                        )
                      : Container(
                          width: radius * 2,
                          height: radius * 2,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade200,
                          ),
                          child: Icon(
                            Icons.person,
                            size: radius * 0.8,
                            color: Colors.grey.shade400,
                          ),
                        ),
                ),
              ),
              if (showEditIcon)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(radius * 0.15),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: radius * 0.35,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// Specialized avatar for different use cases
class LargeProfileAvatar extends StatelessWidget {
  final VoidCallback? onTap;
  final String? imageUrl;
  final File? selectedImage;

  const LargeProfileAvatar({
    Key? key,
    this.onTap,
    this.imageUrl,
    this.selectedImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ProfileAvatar(
      radius: 60,
      showEditIcon: true,
      onTap: onTap,
      imageUrl: imageUrl,
      selectedImage: selectedImage,
    );
  }
}

class SmallProfileAvatar extends StatelessWidget {
  final VoidCallback? onTap;
  final String? imageUrl;
  final File? selectedImage;

  const SmallProfileAvatar({
    Key? key,
    this.onTap,
    this.imageUrl,
    this.selectedImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ProfileAvatar(
      radius: 20,
      showEditIcon: false,
      onTap: onTap,
      imageUrl: imageUrl,
      selectedImage: selectedImage,
    );
  }
}

class MediumProfileAvatar extends StatelessWidget {
  final VoidCallback? onTap;
  final String? imageUrl;
  final File? selectedImage;

  const MediumProfileAvatar({
    Key? key,
    this.onTap,
    this.imageUrl,
    this.selectedImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ProfileAvatar(
      radius: 35,
      showEditIcon: false,
      onTap: onTap,
      imageUrl: imageUrl,
      selectedImage: selectedImage,
    );
  }
}
