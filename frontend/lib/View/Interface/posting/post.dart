// ignore_for_file: deprecated_member_use, use_build_context_synchronously, depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:frontend/utils/Components/custom_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/providers/post_provider.dart';
import 'package:provider/provider.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _formKey = GlobalKey<FormState>();
  final _captionController = TextEditingController();
  List<PlatformFile> _mediaFiles = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'mp4', 'mov', 'webm'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _mediaFiles = result.files;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking media: $e')),
      );
    }
  }

  Widget _buildMediaPreview() {
    if (_mediaFiles.isEmpty) {
      return GestureDetector(
        onTap: _pickMedia,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.image,
                  size: 48, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text('Tap to add photos or videos',
                  style: GoogleFonts.poppins(fontSize: 16)),
            ],
          ),
        ),
      );
    }
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _mediaFiles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final file = _mediaFiles[index];
          final isVideo =
              file.extension?.toLowerCase().contains('mp4') == true ||
                  file.extension?.toLowerCase().contains('mov') == true ||
                  file.extension?.toLowerCase().contains('webm') == true;
          if (isVideo) {
            return _VideoPreview(file: file);
          } else if (file.bytes != null) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(file.bytes!,
                  fit: BoxFit.cover, width: 180, height: 220),
            );
          } else {
            return Container(
              width: 180,
              height: 220,
              color: Theme.of(context).colorScheme.surface,
              child: const Center(
                child: Icon(Icons.broken_image, color: Colors.red, size: 40),
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _createPost() async {
    if (_captionController.text.trim().isEmpty && _mediaFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please add a caption or media',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newPost = await ApiService.createPost(
        caption: _captionController.text.trim(),
        mediaFile: _mediaFiles.first,
      );

      if (mounted) {
        context.read<PostProvider>().addNewPost(newPost);

        setState(() {
          _captionController.clear();
          _mediaFiles = [];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Post Uploaded Successfully',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error creating post: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Create Post',
            style: GoogleFonts.poppins(
                color: theme.colorScheme.onBackground,
                fontWeight: FontWeight.w600)),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildMediaPreview(),
            const SizedBox(height: 24),
            TextFormField(
              controller: _captionController,
              decoration: InputDecoration(
                labelText: 'Write a caption...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
              maxLines: 4,
              maxLength: 2200,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please add a caption';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Post',
              onTap: _createPost,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoPreview extends StatefulWidget {
  final PlatformFile file;
  const _VideoPreview({required this.file});
  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  late VideoPlayerController _controller;
  ChewieController? _chewieController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      // Create a temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
          '${tempDir.path}/temp_video_${DateTime.now().millisecondsSinceEpoch}.${widget.file.extension ?? 'mp4'}');
      await tempFile.writeAsBytes(widget.file.bytes!);

      // Initialize video player with the temporary file
      _controller = VideoPlayerController.file(tempFile);
      await _controller.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _controller,
        autoPlay: false,
        looping: false,
        aspectRatio: 9 / 16,
      );

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const SizedBox(
        width: 180,
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return SizedBox(
      width: 180,
      height: 220,
      child: Chewie(controller: _chewieController!),
    );
  }
}
