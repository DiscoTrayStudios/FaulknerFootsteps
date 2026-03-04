import 'dart:typed_data';

class ImageWithUrl {
  Uint8List? imageData;
  String url;

  ImageWithUrl({this.imageData, required this.url});
}
