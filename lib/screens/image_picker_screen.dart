import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/image_upload_provider.dart';
import '../widgets/cached_image.dart';

/// 画像選択・アップロード画面
class ImagePickerScreen extends ConsumerWidget {
  const ImagePickerScreen({super.key});

  static const String uploadUrl = 'https://api.example.com/upload';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadState = ref.watch(imageUploadProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('画像アップロード')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (uploadState.uploadedUrl != null)
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: CachedImage(
                        imageUrl: uploadState.uploadedUrl!,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'アップロード完了！',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      uploadState.uploadedUrl!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              )
            else if (uploadState.isUploading)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(value: uploadState.progress),
                      const SizedBox(height: 16),
                      Text(
                        'アップロード中... ${(uploadState.progress * 100).toInt()}%',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.cloud_upload,
                        size: 80,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '画像を選択してアップロード',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (uploadState.errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            uploadState.errorMessage!,
                            style: TextStyle(color: Colors.red[900]),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: uploadState.isUploading
                        ? null
                        : () {
                            ref
                                .read(imageUploadProvider.notifier)
                                .pickAndUploadFromCamera(uploadUrl);
                          },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('カメラ'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: uploadState.isUploading
                        ? null
                        : () {
                            ref
                                .read(imageUploadProvider.notifier)
                                .pickAndUploadFromGallery(uploadUrl);
                          },
                    icon: const Icon(Icons.photo_library),
                    label: const Text('ギャラリー'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            if (uploadState.uploadedUrl != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  ref.read(imageUploadProvider.notifier).reset();
                },
                child: const Text('リセット'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
