import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../providers/wedding_provider.dart';

class CreateWeddingScreen extends StatefulWidget {
  const CreateWeddingScreen({super.key});

  @override
  State<CreateWeddingScreen> createState() => _CreateWeddingScreenState();
}

class _CreateWeddingScreenState extends State<CreateWeddingScreen> {
  final _titleController = TextEditingController();
  PlatformFile? _selectedFile;

  void _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() => _selectedFile = result.files.first);
    }
  }

  void _submit() async {
    if (_titleController.text.isEmpty || _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title and select a cover image')),
      );
      return;
    }

    final provider = Provider.of<WeddingProvider>(context, listen: false);
    final wedding = await provider.createWedding(_titleController.text, _selectedFile!);

    if (wedding != null && mounted) {
      context.pushReplacement('/upload/${wedding.id}');
    } else if (provider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error!), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
          backgroundColor: Colors.deepPurpleAccent,
          title: const Text('Create Wedding' ,style: TextStyle(
        color:Colors.white,
        fontWeight: FontWeight.bold
      ))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Start your new project',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Wedding Title',
                hintText: 'e.g. John & Jane Wedding',
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),

                ),
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10, style: BorderStyle.solid),
                ),
                child: _selectedFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _selectedFile!.bytes ?? Uint8List(0), // Web needs bytes, Android might need File
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) => const Center(child: Icon(Icons.image, size: 50)),
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.cloud_upload_outlined, size: 48, color: Colors.deepPurpleAccent),
                          SizedBox(height: 8),
                          Text('Pick Cover Image', style: TextStyle(color: Colors.white54)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 48),
            Consumer<WeddingProvider>(
              builder: (context, provider, _) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: provider.isLoading ? null : _submit,
                  child: provider.isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Create Wedding' ,style: TextStyle(color: Colors.white)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
