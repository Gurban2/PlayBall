import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/services/s3_upload_service.dart';
import '../../../../core/providers.dart';

class PhotoUploadWidget extends ConsumerStatefulWidget {
  final String? currentPhotoUrl;
  final String userId;
  final Function(String photoUrl) onPhotoUploaded;

  const PhotoUploadWidget({
    super.key,
    this.currentPhotoUrl,
    required this.userId,
    required this.onPhotoUploaded,
  });

  @override
  ConsumerState<PhotoUploadWidget> createState() => _PhotoUploadWidgetState();
}

class _PhotoUploadWidgetState extends ConsumerState<PhotoUploadWidget> {
  bool _isUploading = false;
  Uint8List? _selectedImageBytes;

  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      // Получаем байты изображения (работает и на мобильных, и в веб)
      final imageBytes = await pickedFile.readAsBytes();

      setState(() {
        _selectedImageBytes = imageBytes;
        _isUploading = true;
      });

      // Загружаем в S3 используя правильный метод для веб/мобильных
      String? photoUrl;
      if (kIsWeb) {
        // В веб используем метод для Uint8List
        photoUrl = await S3UploadService.uploadUserAvatar(
          imageBytes,
          widget.userId,
        );
      } else {
        // На мобильных можем использовать File
        final imageFile = File(pickedFile.path);
        photoUrl = await S3UploadService.uploadUserPhoto(
          imageFile,
          widget.userId,
        );
      }

                   if (photoUrl != null) {
        // Уведомляем родительский компонент о новом URL фото
        widget.onPhotoUploaded(photoUrl);

        if (mounted) {
          ErrorHandler.showSuccess(context, 'Фото загружено! Нажмите "Сохранить" для применения изменений.');
        }
      } else {
        if (mounted) {
          ErrorHandler.showError(context, 'Ошибка загрузки фото');
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
          } finally {
        if (mounted) {
          setState(() {
            _isUploading = false;
            _selectedImageBytes = null;
          });
        }
      }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Аватар с кнопкой изменения
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: _selectedImageBytes != null
                    ? MemoryImage(_selectedImageBytes!) as ImageProvider
                    : (widget.currentPhotoUrl != null
                        ? NetworkImage(widget.currentPhotoUrl!) as ImageProvider
                        : null),
                child: widget.currentPhotoUrl == null && _selectedImageBytes == null
                    ? Icon(
                        Icons.person,
                        size: 60,
                        color: AppColors.primary,
                      )
                    : null,
              ),
              
              // Оверлей с индикатором загрузки
              if (_isUploading)
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              
              // Кнопка редактирования
              if (!_isUploading)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: InkWell(
                      onTap: _pickAndUploadImage,
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Кнопка смены фото
          if (!_isUploading)
            TextButton.icon(
              onPressed: _pickAndUploadImage,
              icon: const Icon(Icons.photo_library),
              label: Text(widget.currentPhotoUrl == null 
                  ? 'Добавить фото' 
                  : 'Изменить фото'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          
          // Индикатор загрузки
          if (_isUploading) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  'Загрузка фото...',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
} 