import 'package:flutter/material.dart';

class ReportedIssueImage extends StatelessWidget {
  const ReportedIssueImage({required this.imageUrl, super.key});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 180,
        width: double.infinity,
        child: Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;

            final expectedBytes = loadingProgress.expectedTotalBytes;
            return Center(
              child: CircularProgressIndicator(
                value: expectedBytes == null
                    ? null
                    : loadingProgress.cumulativeBytesLoaded / expectedBytes,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => Container(
            color: Theme.of(context).colorScheme.surfaceContainer,
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image_outlined),
          ),
        ),
      ),
    );
  }
}
