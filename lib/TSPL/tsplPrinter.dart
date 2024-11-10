import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart'; // For loading assets
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:image/image.dart' as img; // For image manipulation
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class TSPLPrinter {
  BluetoothConnection? connection;

  Future<void> connect(String address) async {
    try {
      connection = await BluetoothConnection.toAddress(address);
      print('Connected to the printer');
    } catch (e) {
      print('Error connecting to the printer: $e');
    }
  }

  Future<void> printTestText() async {
    if (connection == null || !connection!.isConnected) {
      print("Printer not connected");
      return;
    }

    try {
      // Define TSPL commands with fine-tuned alignment for an 80mm width printer
      String commands = '''
CODEPAGE UTF-8\r\n  // Set code page to UTF-8
SIZE 80 mm,30 mm\r\n
CLS\r\n
TEXT 10,10,"مرحبا"  // Test printing Arabic text
PRINT 1\r\n
''';

      String printCommand = """
\x1B!R
SIZE 80 mm, 105 mm\r\n
CLS\r\n
CODEPAGE UTF-8\r\n  // Set code page to UTF-8
TEXT 150,10,"4",0,1,1,"إيصال الاستلام (نسخة)"\r\n

// Second line: Centered text, black text on white background
TEXT 10, 40, "TSS24.BF2", 0, 1, 1, "--------------------------------------------------------"\r\n
TEXT 170, 60, "4", 0, 1, 1, "Customer Details"\r\n
TEXT 10, 90, "TSS24.BF2", 0, 1, 1, "--------------------------------------------------------"\r\n

TEXT 10, 130, "2", 0, 1, 1, "Customer Name"\r\n
TEXT 225, 130, "2", 0, 1, 1, "|"\r\n
TEXT 250, 130, "2", 0, 1, 1, "Ezat asad ezat khaleeli"\r\n

TEXT 10, 170, "2", 0, 1, 1, "Mobile Number"\r\n
TEXT 225, 170, "2", 0, 1, 1, "|"\r\n
TEXT 250, 170, "2", 0, 1, 1, "0569222046"\r\n

=TEXT 10, 210, "2", 0, 1, 1, "Transaction Date"\r\n
TEXT 225, 210, "2", 0, 1, 1, "|"\r\n
TEXT 250, 210, "2", 0, 1, 1, "2024/01/01"\r\n

TEXT 10, 240, "2", 0, 1, 1, "Voucher Number"\r\n
TEXT 225, 240, "2", 0, 1, 1, "|"\r\n
TEXT 250, 240, "2", 0, 1, 1, "w-101"\r\n

TEXT 10, 280, "3", 0, 1, 1, "----------------------------------------------"\r\n
TEXT 170, 300, "3", 0, 1, 1, "Payment Details"\r\n
TEXT 10, 320, "3", 0, 1, 1, "----------------------------------------------"\r\n

TEXT 10, 360, "2", 0, 1, 1, "payment Method"\r\n
TEXT 225, 360, "2", 0, 1, 1, "|"\r\n
TEXT 250, 360, "2", 0, 1, 1, "w-101"\r\n

TEXT 10, 400, "2", 0, 1, 1, "Amount check"\r\n
TEXT 225, 400, "2", 0, 1, 1, "|"\r\n
TEXT 250, 400, "2", 0, 1, 1, "800.0"\r\n

TEXT 10, 440,"2", 0, 1, 1, "Currency"\r\n
TEXT 225, 440, "2", 0, 1, 1, "|"\r\n
TEXT 250, 440, "2", 0, 1, 1, "ILS"\r\n

TEXT 10, 490, "2", 0, 1, 1, "Check Number"\r\n
TEXT 225, 490, "2", 0, 1, 1, "|"\r\n
TEXT 250, 490, "2", 0, 1, 1, "123456789123456789123456789"\r\n

TEXT 10, 530, "2", 0, 1, 1, "Bank"\r\n
TEXT 225, 530, "2", 0, 1, 1, "|"\r\n
TEXT 250, 530, "2", 0, 1, 1, "Palestine Investemant Bank"\r\n

TEXT 10, 570, "2", 0, 1, 1, "Due Date"\r\n
TEXT 225, 570, "2", 0, 1, 1, "|"\r\n
TEXT 250, 570, "2", 0, 1, 1, "22/02/2025"\r\n

TEXT 10, 610, "3", 0, 1, 1, "----------------------------------------------"\r\n
TEXT 170, 630, "3", 0, 1, 1, "Additional Details"\r\n
TEXT 10, 650, "3", 0, 1, 1, "----------------------------------------------"\r\n

TEXT 10, 690, "2", 0, 1, 1, "User Id"\r\n
TEXT 225, 690, "2", 0, 1, 1, "|"\r\n
TEXT 250, 690, "2", 0, 1, 1, "Sami.Salem"\r\n

TEXT 10, 730, "3", 0, 1, 1, "----------------------------------------------"\r\n
TEXT 20, 750, "2", 0, 1, 1, "Please keep the receipt as proof of payment"\r\n
TEXT 10, 770, "3", 0, 1, 1, "----------------------------------------------"\r\n

// TEXT 10, 730, "TSS24.BF2", 0, 1, 1, "----------------------------------------------"\r\n
// TEXT 20, 750, "TSS24.BF2", 0, 1, 1, "Please keep the receipt as proof of payment"\r\n
// TEXT 10, 770, "TSS24.BF2", 0, 1, 1, "----------------------------------------------"\r\n

PRINT 1\r\n
END
""";

      Uint8List commandBytes = Uint8List.fromList(utf8.encode(commands));

      connection!.output.add(commandBytes);
      await connection!.output.allSent;
      print("Formatted text sent to printer");

    } catch (e) {
      print("Error sending formatted text: $e");
    }
  }

  // Call this method when you are done printing
  void disconnect() {
    if (connection != null) {
      connection!.dispose();
      print("Printer connection closed");
    }
  }

  List<int> _imageToBinaryData2(img.Image bwImage, int widthBytes) {
    List<int> binaryData = [];
    for (int y = 0; y < bwImage.height; y++) {
      for (int x = 0; x < bwImage.width; x += 8) {
        int byte = 0;
        for (int bit = 0; bit < 8; bit++) {
          int pixelX = x + bit;
          if (pixelX < bwImage.width && (bwImage.getPixel(pixelX, y) & 0xFF) == 0) {
            byte |= (1 << (7 - bit)); // Set bit for black pixel
          }
        }
        binaryData.add(byte);
      }
    }
    return binaryData;
  }

  void applyOrderedDithering(img.Image image) {
    List<List<int>> bayerMatrix = [
      [0, 8, 2, 10],
      [12, 4, 14, 6],
      [3, 11, 1, 9],
      [15, 7, 13, 5],
    ];
    int matrixSize = 4;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        int pixel = image.getPixel(x, y);
        int brightness = img.getRed(pixel); // Grayscale value
        int threshold = bayerMatrix[y % matrixSize][x % matrixSize] * 16;

        image.setPixel(x, y, brightness < threshold ? img.getColor(0, 0, 0) : img.getColor(255, 255, 255));
      }
    }
  }

  Future<void> printImage2(String imagePath) async {
    if (connection == null || !connection!.isConnected) {
      print("Printer not connected");
      return;
    }

    try {
      // Load image from assets
      ByteData data = await rootBundle.load(imagePath);
      Uint8List bytes = data.buffer.asUint8List();

      // Decode the image
      img.Image? image = img.decodeImage(bytes);
      if (image == null) {
        print("Error decoding image");
        return;
      }

      // Resize the image to fit the printer width
      int targetWidth = 230; // Width for 80mm printers
      img.Image resizedImage = img.copyResize(image, width: targetWidth);

      // Convert to grayscale and apply ordered dithering
      img.Image bwImage = img.grayscale(resizedImage);
      applyOrderedDithering(bwImage);

      // Image width in bytes (1 byte = 8 pixels)
      int widthBytes = (bwImage.width + 7) ~/ 8;
      int heightDots = bwImage.height;

      // Convert image data to binary
      List<int> bitmapData = _imageToBinaryData2(bwImage, widthBytes);

      // Debugging: Print dimensions and first few bytes of bitmap data
      print("Width in Bytes: $widthBytes, Height in Dots: $heightDots");
      print("First 20 bytes of bitmap data: ${bitmapData.take(20).toList()}");

      // Construct TSPL commands
      String tsplCommands = """
SIZE 80 mm,25 mm\r\n
CLS\r\n
CODEPAGE 1256\r\n  // For Arabic
TEXT 150,10,"4",0,1,1,"إيصال الاستلام (نسخة)"\r\n
PRINT 1\r\n
END\r\n
""";
// BITMAP 10,20,$widthBytes,$heightDots,0,${bitmapData.map((e) => e.toRadixString(16).padLeft(2, '0')).join()}\r\n

      // Send commands to printer
      connection!.output.add(utf8.encode(tsplCommands));
      await connection!.output.allSent;
      print("Image sent to printer successfully");

      // Short delay to ensure the printer processes the print command
      await Future.delayed(Duration(seconds: 1));

      // Send a separate FEED command to finalize the print job
      connection!.output.add(utf8.encode("FEED 20\r\n"));
      await connection!.output.allSent;

    } catch (e) {
      print("Error printing image: $e");
    } finally {
      // Disconnect after the print job is sent and processed
      disconnect();
    }
  }

   Future<void> printArabicText(String text) async {
    // Step 1: Create an image with the Arabic text
    ui.Image image = await createTextImage(text, 300, 80);

    // Step 2: Convert the image to binary data for TSPL
    List<int> binaryData = await imageToBinaryData(image);

    // Step 3: Print the image with TSPL
 //   printImage(binaryData, (image.width + 7) ~/ 8, image.height);
  }

   Future<ui.Image> createTextImage(String text, double width, double height) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = Colors.black;

    // Draw a white background
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), Paint()..color = Colors.white);

    // Draw the Arabic text onto the canvas
    final textStyle = TextStyle(color: Colors.black, fontSize: 20);
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.rtl);

    textPainter.layout(maxWidth: width);
    textPainter.paint(canvas, Offset(10, 10));

    return recorder.endRecording().toImage(width.toInt(), height.toInt());
  }

   Future<List<int>> imageToBinaryData(ui.Image image) async {
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return [];

    // Convert the image data to grayscale and binary format
    int width = image.width;
    int height = image.height;
    List<int> binaryData = [];

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x += 8) {
        int byte = 0;
        for (int bit = 0; bit < 8; bit++) {
          int pixelX = x + bit;
          if (pixelX < width) {
            int pixelIndex = (y * width + pixelX) * 4;
            int r = byteData.getUint8(pixelIndex);
            int g = byteData.getUint8(pixelIndex + 1);
            int b = byteData.getUint8(pixelIndex + 2);
            int grayscale = (r + g + b) ~/ 3;
            if (grayscale < 128) {
              byte |= (1 << (7 - bit)); // Set bit for dark pixel
            }
          }
        }
        binaryData.add(byte);
      }
    }
    return binaryData;
  }

   Future<void> printImage() async {
     // Load the BMP image from assets
     ByteData data = await rootBundle.load('assets/temp.bmp');
     Uint8List bmpBytes = data.buffer.asUint8List();

     // Step 1: Upload the image to printer memory
     String uploadCommand = 'DOWNLOAD "SAMPLE.GRF",${bmpBytes.length}\r\n';
     // Step 2: Prepare the print command
     String printCommand = '''
SIZE 80 mm,30 mm\r\n
CLS
BOX 120,120,550,150,4,20
PRINT 1
''';

     if (connection != null && connection!.isConnected) {
       // Send upload command
       connection!.output.add(utf8.encode(uploadCommand));
       await connection!.output.allSent;

       // Send image data
       connection!.output.add(bmpBytes);
       await connection!.output.allSent;

       // Send print command
       connection!.output.add(utf8.encode(printCommand));
       await connection!.output.allSent;

       print("Image uploaded and printed successfully");
     } else {
       print("Error: Printer is not connected");
     }
  }
}
