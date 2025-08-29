import 'dart:typed_data';
import 'package:dio/dio.dart';

class BillValidator {
  /// Accepts Uint8List and sends to backend ONNX API
  Future<String> validate(Uint8List imageBytes) async {
    final dio = Dio();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(imageBytes, filename: 'bill.jpg'),
    });
    final response = await dio.post(
      'http://172.20.10.3:8001/validate-bill',
      data: formData,
    );
    if (response.statusCode == 200) {
      return response.data['result'] as String;
    } else {
      throw Exception('Failed to validate bill image');
    }
  }
}
