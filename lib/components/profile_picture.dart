import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:KlikGadget/main.dart';

class Avatar extends StatefulWidget {
  const Avatar({
    super.key,
    required this.imageUrl,
    required this.onUpload,
  });

  final String? imageUrl;
  final void Function(String) onUpload;

  @override
  State<Avatar> createState() => _AvatarState();
}

class _AvatarState extends State<Avatar> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 75,
          backgroundImage:
              widget.imageUrl != null ? NetworkImage(widget.imageUrl!) : null,
          child: widget.imageUrl == null
              ? const Icon(
                  Icons.person,
                  size: 50,
                  color: Colors.white,
                )
              : null,
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _upload,
          child: Text(_isLoading ? 'Uploading...' : 'Upload'),
        ),
        if (_errorMessage != null)
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
          ),
      ],
    );
  }

  Future<void> _upload() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final imagePicker = ImagePicker();
    final XFile? pickedImage = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85, // Adjust image quality as needed
    );

    if (pickedImage == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No image selected.';
      });
      return;
    }

    try {
      final bytes = await pickedImage.readAsBytes();
      final fileExt = pickedImage.name.split('.').last;
      final fileName = '${DateTime.now().toIso8601String()}.$fileExt';
      final filePath = fileName;

      await supabase.storage.from('user_picture').uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(contentType: pickedImage.mimeType),
          );

      final imageUrlResponse = await supabase.storage
          .from('user_picture')
          .createSignedUrl(filePath,
              60 * 60 * 24 * 365 * 10); // Adjust expiration time as needed

      widget.onUpload(imageUrlResponse);
    } on StorageException catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unexpected error occurred';
      });
    }
  }
}
