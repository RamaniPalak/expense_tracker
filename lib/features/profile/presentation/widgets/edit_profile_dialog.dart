import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';
import 'package:expense_tracker/core/di/injection_container.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';

class EditProfileDialog extends StatefulWidget {
  final String initialName;
  final String? initialImagePath;

  const EditProfileDialog({
    super.key,
    required this.initialName,
    this.initialImagePath,
  });

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late TextEditingController _nameController;
  String? _selectedImagePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _selectedImagePath = widget.initialImagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      // imageQuality (0–100) compresses the JPEG before it's returned.
      // Combined with maxWidth/maxHeight, a typical 3–5 MB photo is
      // reduced to ~100–200 KB — much faster to upload to Cloudinary.
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 72,
      );

      if (pickedFile != null) {
        // Copy compressed image to app's document directory for a stable path
        final directory = await getApplicationDocumentsDirectory();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_profile.jpg';
        final savedImagePath = p.join(directory.path, fileName);

        await File(pickedFile.path).copy(savedImagePath);

        setState(() {
          _selectedImagePath = savedImagePath;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await sl<IAuthRepository>().updateProfile(name, _selectedImagePath);
      if (mounted) {
        Navigator.pop(context, true); // Signal success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Builds the profile image widget for the dialog preview.
  /// - Cloudinary/remote URL → [Image.network]
  /// - Local file (freshly picked) → [Image.file]
  /// - No image → placeholder icon
  Widget _buildDialogImage(dynamic c) {
    if (_selectedImagePath != null && _selectedImagePath!.isNotEmpty) {
      if (_selectedImagePath!.startsWith('http')) {
        return Image.network(
          _selectedImagePath!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(Icons.person, size: 50, color: c.textSecondary),
        );
      }
      final file = File(_selectedImagePath!);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }
    return Icon(Icons.person, size: 50, color: c.textSecondary);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    return Dialog(
      backgroundColor: c.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Edit Profile",
              style: AppTextStyles.heading2.copyWith(color: c.textPrimary),
            ),
            const SizedBox(height: 24),
            
            // Profile Image Picker
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: c.background,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildDialogImage(c),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.card, width: 3),
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Name Input
            TextField(
              controller: _nameController,
              style: TextStyle(color: c.textPrimary),
              decoration: InputDecoration(
                labelText: "Display Name",
                labelStyle: TextStyle(color: c.textSecondary),
                filled: true,
                fillColor: c.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.person_outline, color: c.textSecondary),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: TextStyle(color: c.textSecondary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading 
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 18, 
                                height: 18, 
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Uploading...",
                                style: TextStyle(color: Colors.white, fontSize: 11),
                              ),
                            ],
                          )
                        : const Text(
                            "Save",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
