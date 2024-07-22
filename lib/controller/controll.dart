import 'dart:math';

import 'package:flutter/material.dart';
import 'package:frintensorflow/model/classifymodel.dart';
import 'package:tflite_flutter_helper_plus/tflite_flutter_helper_plus.dart';
import 'package:tflite_flutter_plus/tflite_flutter_plus.dart';
import 'package:image/image.dart' as img;

import '../model/classifiermodel.dart';

typedef ClassifierLabels = List<String>;

class Classifier {
  final ClassifierLabels _labels;
  final ClassifierModel _model;

  Classifier._({
    required ClassifierLabels labels,
    required ClassifierModel model,
  })  : _labels = labels,
        _model = model;

  static Future<Classifier?> loadWith({
    required String labelsFileName,
    required String modelFileName,
  }) async {
    try {
      final labels = await _loadLabels(labelsFileName);
      final model = await _loadModel(modelFileName);
      return Classifier._(labels: labels, model: model);
    } catch (e) {
      debugPrint('Can\'t initialize Classifier: ${e.toString()}');
      if (e is Error) {
        debugPrintStack(stackTrace: e.stackTrace);
      }
      return null;
    }
  }

  ClassifierCategory predict(img.Image image) {
    debugPrint(
      'Image: ${image.width}x${image.height}, '
      'size: ${image.length} bytes',
    );

    final inputImage = _preProcessInput(image);

    debugPrint(
      'Pre-processed image: ${inputImage.width}x${image.height}, '
      'size: ${inputImage.buffer.lengthInBytes} bytes',
    );
// #1
    final outputBuffer = TensorBuffer.createFixedSize(
      _model.outputShape,
      _model.outputType,
    );

// #2
    _model.interpreter.run(inputImage.buffer, outputBuffer.buffer);
    debugPrint('OutputBuffer: ${outputBuffer.getDoubleList()}');
    // Run inference
    _model.interpreter.run(inputImage.buffer, outputBuffer.buffer);

    // Post Process the outputBuffer
    final resultCategories = _postProcessOutput(outputBuffer);
    final topResult = resultCategories.first;

    debugPrint('Top category: $topResult');
    return topResult;
  }

  static Future<ClassifierLabels> _loadLabels(String labelsFileName) async {
    // #1
    final rawLabels = await FileUtil.loadLabels(labelsFileName);

    // #2
    final labels = rawLabels
        .map((label) => label.substring(label.indexOf(' ')).trim())
        .toList();

    debugPrint('Labels: $labels');
    return labels;
  }

  static Future<ClassifierModel> _loadModel(String modelFileName) async {
    // #1
    final interpreter = await Interpreter.fromAsset(modelFileName);
    // #2
    final inputShape = interpreter.getInputTensor(0).shape;
    final outputShape = interpreter.getOutputTensor(0).shape;

    debugPrint('Input shape: $inputShape');
    debugPrint('Output shape: $outputShape');

    // #3
    final inputType = interpreter.getInputTensor(0).type;
    final outputType = interpreter.getOutputTensor(0).type;

    debugPrint('Input type: $inputType');
    debugPrint('Output type: $outputType');

    return ClassifierModel(
      interpreter: interpreter,
      inputShape: inputShape,
      outputShape: outputShape,
      inputType: inputType,
      outputType: outputType,
    );
  }

  TensorImage _preProcessInput(img.Image image) {
    // #1
    final inputTensor = TensorImage(_model.inputType);
    inputTensor.loadImage(image);

    // #2
    final minLength = min(inputTensor.height, inputTensor.width);
    final cropOp = ResizeWithCropOrPadOp(minLength, minLength);

    // #3
    final shapeLength = _model.inputShape[1];
    final resizeOp = ResizeOp(shapeLength, shapeLength, ResizeMethod.bilinear);

    // #4
    final normalizeOp = NormalizeOp(127.5, 127.5);

    // #5
    final imageProcessor = ImageProcessorBuilder()
        .add(cropOp)
        .add(resizeOp)
        .add(normalizeOp)
        .build();

    imageProcessor.process(inputTensor);

    // #6
    return inputTensor;
  }

  List<ClassifierCategory> _postProcessOutput(TensorBuffer outputBuffer) {
    // #1
    final probabilityProcessor = TensorProcessorBuilder().build();

    probabilityProcessor.process(outputBuffer);

    // #2
    final labelledResult = TensorLabel.fromList(_labels, outputBuffer);

    // #3
    final categoryList = <ClassifierCategory>[];
    labelledResult.getMapWithFloatValue().forEach((key, value) {
      final category = ClassifierCategory(key, value);
      categoryList.add(category);
      debugPrint('label: ${category.label}, score: ${category.score}');
    });

    // #4
    categoryList.sort((a, b) => (b.score > a.score ? 1 : -1));

    return categoryList;
  }
}


// typedef ClassifierLabels = List<String>;

// class Controller extends GetxController {
//   ClassifierModel? _model;
//   ClassifierLabels _labels;
//   // logic to load your teachable machine labels
//   Future<ClassifierLabels> _loadLabels(String labelsFileName) async {
//     final rawLabels = await FileUtil.loadLabels(labelsFileName);

//     // Remove the index number from the label
//     final labels = rawLabels
//         .map((label) => label.substring(label.indexOf(' ')).trim())
//         .toList();

//     debugPrint('Labels: $labels');
//     return labels;
//   }

//   // logic to load your teachable machine models
//   static Future<ClassifierModel> _loadModel(String modelFileName) async {
//     final interpreter = await Interpreter.fromAsset(modelFileName);

//     // Get input and output shape from the model
//     final inputShape = interpreter.getInputTensor(0).shape;
//     final outputShape = interpreter.getOutputTensor(0).shape;

//     debugPrint('Input shape: $inputShape');
//     debugPrint('Output shape: $outputShape');

//     // Get input and output type from the model
//     final inputType = interpreter.getInputTensor(0).type;
//     final outputType = interpreter.getOutputTensor(0).type;

//     debugPrint('Input type: $inputType');
//     debugPrint('Output type: $outputType');

//     return ClassifierModel(
//       interpreter: interpreter,
//       inputShape: inputShape,
//       outputShape: outputShape,
//       inputType: inputType,
//       outputType: outputType,
//     );
//   }

//   Future<ClassifyModel?> loadWith({
//     required String labelsFileName,
//     required String modelFileName,
//   }) async {
//     try {
//       final labels = await _loadLabels(labelsFileName);
//       final model = await _loadModel(modelFileName);
//       final classifymodel = ClassifyModel(labels: labels, model: model);
//       return classifymodel;
//     } catch (e) {
//       debugPrint('Can\'t initialize Classifier: ${e.toString()}');
//       if (e is Error) {
//         debugPrintStack(stackTrace: e.stackTrace);
//       }
//       return null;
//     }
//   }

//   void close() {
//     if (_model != null) {
//       _model!.interpreter.close();
//     }
//   }

//   ClassifierCategory predict(img.Image image) {
//     debugPrint(
//       'Image: ${image.width}x${image.height}, '
//       'size: ${image.length} bytes',
//     );

//     // Load the image and convert it to TensorImage for TensorFlow Input
//     final inputImage = _preProcessInput(image);

//     debugPrint(
//       'Pre-processed image: ${inputImage.width}x${image.height}, '
//       'size: ${inputImage.buffer.lengthInBytes} bytes',
//     );

//     // Define the output buffer
//     final outputBuffer = TensorBuffer.createFixedSize(
//       _model!.outputShape,
//       _model!.outputType,
//     );

//     // Run inference
//     _model!.interpreter.run(inputImage.buffer, outputBuffer.buffer);

//     debugPrint('OutputBuffer: ${outputBuffer.getDoubleList()}');

//     // Post Process the outputBuffer
//     final resultCategories = _postProcessOutput(outputBuffer);
//     final topResult = resultCategories.first;

//     debugPrint('Top category: $topResult');

//     return topResult;
//   }

//   TensorImage _preProcessInput(img.Image image) {
//     // #1
//     var inputTensor = TensorImage(_model!.inputType);
//     inputTensor.loadImage(image);

//     // #2
//     final minLength = min(inputTensor.height, inputTensor.width);
//     final cropOp = ResizeWithCropOrPadOp(minLength, minLength);

//     // #3
//     final shapeLength = _model!.inputShape[1];
//     final resizeOp = ResizeOp(shapeLength, shapeLength, ResizeMethod.bilinear);

//     // #4
//     final normalizeOp = NormalizeOp(127.5, 127.5);

//     // #5
//     final imageProcessor = ImageProcessorBuilder()
//         .add(cropOp)
//         .add(resizeOp)
//         .add(normalizeOp)
//         .build();

//     imageProcessor.process(inputTensor);

//     // #6
//     return inputTensor;
//   }

//   List<ClassifierCategory> _postProcessOutput(TensorBuffer outputBuffer) {
//     final probabilityProcessor = TensorProcessorBuilder().build();

//     probabilityProcessor.process(outputBuffer);

//     final labelledResult = TensorLabel.fromList(_labels!, outputBuffer);

//     final categoryList = <ClassifierCategory>[];
//     labelledResult.getMapWithFloatValue().forEach((key, value) {
//       final category = ClassifierCategory(key, value);
//       categoryList.add(category);
//       debugPrint('label: ${category.label}, score: ${category.score}');
//     });
//     categoryList.sort((a, b) => (b.score > a.score ? 1 : -1));

//     return categoryList;
//   }
// }

// import 'dart:typed_data';

// import 'package:camera/camera.dart';
// import 'package:image/image.dart' as image_lib;

// // ImageUtils
// class ImageUtils {
//   // Converts a [CameraImage] in YUV420 format to [imageLib.Image] in RGB format
//   static image_lib.Image? convertCameraImage(CameraImage cameraImage) {
//     if (cameraImage.format.group == ImageFormatGroup.yuv420) {
//       return convertYUV420ToImage(cameraImage);
//     } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
//       return convertBGRA8888ToImage(cameraImage);
//     } else {
//       return null;
//     }
//   }

//   // Converts a [CameraImage] in BGRA888 format to [imageLib.Image] in RGB format
//   // static image_lib.Image convertBGRA8888ToImage(CameraImage cameraImage) {
//   //   image_lib.Image img = image_lib.Image.fromBytes(
//   //       width: cameraImage.planes[0].width!,
//   //       height: cameraImage.planes[0].height!,
//   //       bytes: cameraImage.planes[0].bytes.buffer,
//   //       order: image_lib.ChannelOrder.bgra);

//   //   return img;

//   // }

//   static image_lib.Image convertYUV420ToImage(CameraImage cameraImage) {
//     final imageWidth = cameraImage.width;
//     final imageHeight = cameraImage.height;

//     final yBuffer = cameraImage.planes[0].bytes;
//     final uBuffer = cameraImage.planes[1].bytes;
//     final vBuffer = cameraImage.planes[2].bytes;

//     final int yRowStride = cameraImage.planes[0].bytesPerRow;
//     final int yPixelStride = cameraImage.planes[0].bytesPerPixel!;

//     final int uvRowStride = cameraImage.planes[1].bytesPerRow;
//     final int uvPixelStride = cameraImage.planes[1].bytesPerPixel!;

//     final image = image_lib.Image(width: imageWidth, height: imageHeight);

//     for (int h = 0; h < imageHeight; h++) {
//       int uvh = (h / 2).floor();

//       for (int w = 0; w < imageWidth; w++) {
//         int uvw = (w / 2).floor();

//         final yIndex = (h * yRowStride) + (w * yPixelStride);

//         // Y plane should have positive values belonging to [0...255]
//         final int y = yBuffer[yIndex];

//         // U/V Values are subsampled i.e. each pixel in U/V chanel in a
//         // YUV_420 image act as chroma value for 4 neighbouring pixels
//         final int uvIndex = (uvh * uvRowStride) + (uvw * uvPixelStride);

//         // U/V values ideally fall under [-0.5, 0.5] range. To fit them into
//         // [0, 255] range they are scaled up and centered to 128.
//         // Operation below brings U/V values to [-128, 127].
//         final int u = uBuffer[uvIndex];
//         final int v = vBuffer[uvIndex];

//         // Compute RGB values per formula above.
//         int r = (y + v * 1436 / 1024 - 179).round();
//         int g = (y - u * 46549 / 131072 + 44 - v * 93604 / 131072 + 91).round();
//         int b = (y + u * 1814 / 1024 - 227).round();

//         r = r.clamp(0, 255);
//         g = g.clamp(0, 255);
//         b = b.clamp(0, 255);

//         image.setPixelRgb(w, h, r, g, b);
//       }
//     }
//     return image;
//   }
// }
