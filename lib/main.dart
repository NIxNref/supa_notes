import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ubqfqekyweprshzehgxq.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVicWZxZWt5d2VwcnNoemVoZ3hxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDY4NjI2NDcsImV4cCI6MjAyMjQzODY0N30.hUKt9DLb9ivCRAry_9P8JUP9_n7h4silOd3v5R-wTSs',
  );
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  MainApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SupaNotes',
      home: MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _noteStream =
      Supabase.instance.client.from('note').stream(primaryKey: ['id']);
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SupaNotes'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _noteStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final notes = snapshot.data!;

          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              return Card(
                elevation: 3,
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(notes[index]['body']),
                  // Display the image if it exists
                  leading: notes[index]['image'] != null
                      ? Image.memory(
                          base64Decode(notes[index]['image']),
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () async {
                          await _showEditNoteDialog(context, notes[index]);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () async {
                          await _deleteNoteDialog(context, notes[index]);
                        },
                      ),
                    ],
                  ),
                  onTap: () async {
                    await _showEditNoteDialog(context, notes[index]);
                  },
                  onLongPress: () async {
                    await _deleteNoteDialog(context, notes[index]);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _showAddNoteDialog(context);
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddNoteDialog(BuildContext context) async {
    XFile? _imageFile;

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SimpleDialog(
              title: Text('Add Note'),
              contentPadding: EdgeInsets.symmetric(horizontal: 10),
              children: [
                TextFormField(
                  controller: _textController,
                  onFieldSubmitted: (value) async {
                    await Supabase.instance.client.from('note').insert({
                      'body': value,
                      'image': _imageFile != null
                          ? await _convertImageToBase64(_imageFile!)
                          : null,
                    });

                    // Close the dialog after data is inserted
                    Navigator.pop(context);
                  },
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    _imageFile = await _imagePicker.pickImage(
                        source: ImageSource.gallery);
                    setState(
                        () {}); // Refresh the dialog to show the selected image
                  },
                  icon: Icon(Icons.image),
                  label: Text('Choose Image'),
                ),
                _imageFile != null
                    ? Image.file(File(
                        _imageFile!.path)) // Use File object instead of XFile
                    : Container(),
                ElevatedButton.icon(
                  onPressed: () async {
                    final value = _textController.text;
                    if (value.isNotEmpty) {
                      await Supabase.instance.client.from('note').insert({
                        'body': value,
                        'image': _imageFile != null
                            ? await _convertImageToBase64(_imageFile!)
                            : null,
                      });

                      // Close the dialog after data is inserted
                      Navigator.pop(context);
                    } else {
                      // Show a message to the user to input some text
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please enter some text.'),
                        ),
                      );
                    }
                  },
                  icon: Icon(Icons.save),
                  label: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditNoteDialog(
      BuildContext context, Map<String, dynamic> note) async {
    XFile? _imageFile;
    _textController.text = note['body'];

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SimpleDialog(
              title: Text('Edit Note'),
              contentPadding: EdgeInsets.symmetric(horizontal: 10),
              children: [
                TextFormField(
                  controller: _textController,
                  onFieldSubmitted: (value) async {
                    await Supabase.instance.client.from('note').update({
                      'body': value,
                      'image': _imageFile != null
                          ? await _convertImageToBase64(_imageFile!)
                          : null,
                    }).eq('id', note['id']);

                    // Close the dialog after data is updated
                    Navigator.pop(context);
                  },
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    _imageFile = await _imagePicker.pickImage(
                        source: ImageSource.gallery);
                    setState(
                        () {}); // Refresh the dialog to show the selected image
                  },
                  icon: Icon(Icons.image),
                  label: Text('Choose Image'),
                ),
                _imageFile != null
                    ? Image.file(File(
                        _imageFile!.path)) // Use File object instead of XFile
                    : Container(),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (_textController.text.isNotEmpty) {
                      await Supabase.instance.client.from('note').update({
                        'body': _textController.text,
                        'image': _imageFile != null
                            ? await _convertImageToBase64(_imageFile!)
                            : null,
                      }).eq('id', note['id']);

                      // Close the dialog after data is updated
                      Navigator.pop(context);
                    } else {
                      // Show a message to the user to input some text
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please enter some text.'),
                        ),
                      );
                    }
                  },
                  icon: Icon(Icons.save),
                  label: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteNoteDialog(
      BuildContext context, Map<String, dynamic> note) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Note'),
          content: Text('Are you sure you want to delete this note?'),
          actions: [
            TextButton(
              onPressed: () async {
                await Supabase.instance.client
                    .from('note')
                    .delete()
                    .eq('id', note['id']);
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Delete'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<String> _convertImageToBase64(XFile imageFile) async {
    List<int> imageBytes = await imageFile.readAsBytes();
    return base64Encode(imageBytes);
  }
}
