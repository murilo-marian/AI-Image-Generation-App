import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<AssetEntity> _images = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  //carrega as imagens, usa o photomanager pra carregar todos os albuns e depois pega o com o nome "Image Generator" e dá display nas imagens
  Future<void> _loadImages() async {
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
    );

    final AssetPathEntity imageGeneratorAlbum = albums.firstWhere(
      (album) => album.name == "Image Generator",
      orElse: () => albums.first,
    );

    final List<AssetEntity> images =
        await imageGeneratorAlbum.getAssetListRange(
      start: 0,
      end: 100,
    );

    setState(() {
      _images = images;
      _isLoading = false;
    });
  }

  Future<void> _openImage(AssetEntity imageEntity) async {
    final File? imageFile = await imageEntity.file;
    if (imageFile != null) {
      await OpenFile.open(imageFile.path);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar a imagem.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.only(
                  top: 50, bottom: 16, left: 16, right: 16),
              child: AnimatedOpacity(
                opacity: _isLoading ? 0 : 1,
                duration: Duration(seconds: 1),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 4.0,
                    mainAxisSpacing: 4.0,
                  ),
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    final AssetEntity imageEntity = _images[index];
                    return FutureBuilder<File?>(
                      future: imageEntity.file,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done &&
                            snapshot.data != null) {
                          final File imageFile = snapshot.data!;
                          return GestureDetector(
                            onTap: () => _openImage(imageEntity),
                            child: Image.file(
                              filterQuality: FilterQuality.none,
                              imageFile,
                              fit: BoxFit.cover,
                            ),
                          );
                        }
                        return Center(child: CircularProgressIndicator());
                      },
                    );
                  },
                ),
              ),
            ),
    );
  }
}
