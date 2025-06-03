// ignore_for_file: deprecated_member_use, use_build_context_synchronously, depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:frontend/utils/Components/custom_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:frontend/services/api_service.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _formKey = GlobalKey<FormState>();
  final _captionController = TextEditingController();
  final bool _isLoading = false;
  List<PlatformFile> _mediaFiles = [];

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
    if (!_formKey.currentState!.validate() || _mediaFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please select at least one image or video and add a caption'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
      // Prepare multipart request
      const backendUrl =
          'http://192.168.100.62:3000/api/posts'; // Use your actual backend URL here
      final request = http.MultipartRequest('POST', Uri.parse(backendUrl));
      request.fields['caption'] = _captionController.text.trim();
      final token = ApiService.token;
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      for (final file in _mediaFiles) {
        if (file.bytes == null || file.bytes!.isEmpty) {
          if (mounted) Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('One or more selected files are invalid.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        final ext = file.extension?.toLowerCase() ?? '';
        final isVideo = ['mp4', 'mov', 'webm'].contains(ext);
        String contentType;
        if (isVideo) {
          contentType = 'video/$ext';
        } else if (ext == 'png') {
          contentType = 'image/png';
        } else {
          contentType = 'image/jpeg';
        }
        request.files.add(http.MultipartFile.fromBytes(
          'media',
          file.bytes!,
          filename: file.name,
          contentType: MediaType.parse(contentType),
        ));
      }
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (mounted) Navigator.pop(context);
      if (response.statusCode == 201) {
        setState(() {
          _captionController.clear();
          _mediaFiles = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating post: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating post: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
          '${tempDir.path}/temp_video_${DateTime.now().millisecondsSinceEpoch}.mp4');
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
