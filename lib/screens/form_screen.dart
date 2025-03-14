import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gal/gal.dart';

class FormScreen extends StatefulWidget {
  const FormScreen({super.key});

  @override
  _FormScreenState createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _generationsController = TextEditingController();
  final _mutationRateController = TextEditingController();
  final _popSizeController = TextEditingController();
  String? _imagePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedValues();
  }

  //envia o formulário
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _imagePath != null) {
      setState(() {
        _isLoading = true;
      });
      final generations = int.parse(_generationsController.text);
      final mutationRate = double.parse(_mutationRateController.text);
      final popSize = int.parse(_popSizeController.text);

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('pop_size', popSize);
        await prefs.setInt('num_generations', generations);
        await prefs.setDouble('mutation_rate', mutationRate);

        final uri = Uri.parse("http://172.16.2.77:5000/run-genetic-algorithm");
        final request = http.MultipartRequest('POST', uri)
          ..fields['pop_size'] = popSize.toString()
          ..fields['num_generations'] = generations.toString()
          ..fields['mutation_rate'] = mutationRate.toString()
          ..files.add(await http.MultipartFile.fromPath('image', _imagePath!));

        final response = await request.send();

        if (response.statusCode == 200) {
          final Uint8List generatedImageBytes = await response.stream.toBytes();

          final Directory appDir = await getApplicationDocumentsDirectory();
          final String imageName =
              'generated_image_${DateTime.now().millisecondsSinceEpoch}.png';
          final File savedImage = File('${appDir.path}/$imageName');
          await savedImage.writeAsBytes(generatedImageBytes);
          await Gal.putImage('${appDir.path}/$imageName',
              album: 'Image Generator');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Imagem gerada e salva com sucesso!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ${response.statusCode}')));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  //escolher imagem a ser usada
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
      });
    }
  }

  //carrega os parâmetros salvos no shared preferences
  Future<void> _loadSavedValues() async {
    final prefs = await SharedPreferences.getInstance();
    final savedGenerations = prefs.getInt('num_generations');
    final savedMutationRate = prefs.getDouble('mutation_rate');
    final savedPopSize = prefs.getInt('pop_size');

    if (savedGenerations != null) {
      _generationsController.text = savedGenerations.toString();
    }
    if (savedMutationRate != null) {
      _mutationRateController.text = savedMutationRate.toString();
    }
    if (savedPopSize != null) {
      _popSizeController.text = savedPopSize.toString();
    }
  }

  // Popup de confirmação
  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar Envio'),
          content: Text('Você tem certeza que deseja enviar os dados?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _submitForm();
              },
              child: Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  //front
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.only(
                  top: 35, bottom: 16, left: 16, right: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: _generationsController,
                      decoration: InputDecoration(
                        labelText: 'Número de Gerações',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira o número de gerações';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _mutationRateController,
                      decoration: InputDecoration(
                        labelText: 'Taxa de Mutação',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira a taxa de mutação';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _popSizeController,
                      decoration: InputDecoration(
                        labelText: 'Tamanho da População',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira o tamanho da população';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _pickImage,
                      child: Text('Escolher Imagem'),
                    ),
                    SizedBox(height: 20),
                    if (_imagePath != null)
                      Text('Imagem selecionada: $_imagePath'),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _showConfirmationDialog,
                      child: Text('Enviar'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
