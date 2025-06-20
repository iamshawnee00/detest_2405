// lib/screens/scanner/qr_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
// import 'package:provider/provider.dart'; // Unused import
// import '../../providers/user_provider.dart'; // Unused import
// import '../../models/user_model.dart'; // UserModel is not directly used here after removing placeholder logic
// import '../profile/profile_screen.dart'; // If navigating to a user's profile

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    // Facing.back by default
    // detectionTimeoutMs: 250, // You can set a timeout
  );
  bool _isProcessing = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_isProcessing) return; 
    if (!mounted) return; // Check if widget is still in the tree

    setState(() {
      _isProcessing = true;
    });

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final String scannedData = barcodes.first.rawValue!;
      cameraController.stop(); 

      Uri? uri = Uri.tryParse(scannedData);
      String messageToShow = "Scanned: $scannedData";
      String? userIdFromScan;

      if (uri != null && uri.scheme == 'foodieapp' && uri.host == 'user' && uri.queryParameters.containsKey('id')) {
        userIdFromScan = uri.queryParameters['id'];
        messageToShow = "Foodie User ID: $userIdFromScan";
      }
      
      if (!mounted) return; // Check mounted before showing dialog

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) { // Use a different context name for dialog
          return AlertDialog(
            title: const Text('QR Code Scanned!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(messageToShow), // Make it selectable
                if (userIdFromScan != null) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.of(dialogContext).pop(); // Close this dialog using dialogContext
                      // Action with userIdFromScan
                      await _handleScannedUser(userIdFromScan!);
                    },
                    child: const Text('View Profile / Add Friend'),
                  )
                ]
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Scan Again'),
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Use dialogContext
                  if (mounted) {
                    setState(() {
                      _isProcessing = false;
                    });
                    cameraController.start(); 
                  }
                },
              ),
               TextButton(
                child: const Text('Close'),
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Use dialogContext
                  if (mounted) {
                     Navigator.of(context).pop(); // Go back from scanner screen using widget's context
                  }
                },
              ),
            ],
          );
        },
      ).then((_) {
        // This block executes after the dialog is dismissed.
        // Current "Close" button already pops twice.
        // If "Scan Again" was pressed, _isProcessing is already false and camera started.
      });
    } else {
       if (mounted) {
          setState(() {
            _isProcessing = false; 
          });
       }
    }
  }

  Future<void> _handleScannedUser(String userId) async {
    if (!mounted) return;
    // final userProvider = Provider.of<UserProvider>(context, listen: false); // Currently unused

    // TODO: Implement action with userIdFromScan (e.g., fetch user, navigate to profile, or add friend)
    // For example:
    // UserModel? scannedUser = await userProvider.getUserById(userId);
    // if (!mounted) return;
    // if (scannedUser != null) {
    //   Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(userId: scannedUser.id))); // Assuming ProfileScreen takes userId or UserModel
    // } else {
    //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User not found.'), backgroundColor: Colors.red));
    // }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Action for user ID: $userId is pending implementation.')),
    );
    
    // Consider navigation flow after handling. If dialog is dismissed and this function is called,
    // this pop might be redundant if the user expects to stay on the previous screen.
    // For now, if this function is called, it implies an action was taken, and we pop the scanner.
    // if (mounted) {
    //   Navigator.of(context).pop(); 
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Foodie QR Code'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder<TorchState>(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                // The 'torchState' getter is directly available on MobileScannerController.
                // No default case needed if all enum values are handled explicitly.
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                }
              },
            ),
            tooltip: 'Toggle Torch',
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder<CameraFacing>(
              valueListenable: cameraController.cameraFacingState,
              builder: (context, state, child) {
                // The 'cameraFacingState' getter is directly available on MobileScannerController.
                // No default case needed if all enum values are handled explicitly.
                switch (state) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            tooltip: 'Switch Camera',
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _handleBarcode,
            errorBuilder: (context, error, child) {
              // For MobileScannerException, access error details like:
              // error.errorDetails?.message or error.errorCode.name
              // The 'name' getter might not be directly on MobileScannerException.
              String errorMessage = 'Error starting camera.';
              if (error.errorDetails != null) {
                errorMessage += '\n${error.errorDetails!.message ?? error.errorCode.name}';
              } else {
                errorMessage += '\n${error.errorCode.name}';
              }
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(errorMessage, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center,),
                ),
              );
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity, 
              padding: const EdgeInsets.all(16.0),
              color: Colors.black.withAlpha((0.4 * 255).round()),
              child: const Text(
                'Point your camera at a Foodie QR Code',
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
