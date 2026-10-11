import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MagicCropApp());
}

class MagicCropApp extends StatelessWidget {
  const MagicCropApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MagicCrop AI',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _photosCount = 0;
  bool _isPremium = false;
  File? _selectedImage;
  File? _processedImage;
  bool _isLoading = false;

  final String _apiKey = "YOUR_REMOVE_BG_API_KEY_HERE";

  @override
  void initState() {
    super.initState();
    _loadUserStatus();
  }

  Future<void> _loadUserStatus() async {
    final prefs = await SharedPreferences.getInstance();
    String? lastResetDate = prefs.getString('lastResetDate');
    String today = DateTime.now().toIso8601String().split('T')[0];

    if (lastResetDate != today) {
      await prefs.setInt('photosCount', 0);
      await prefs.setString('lastResetDate', today);
    }

    setState(() {
      _photosCount = prefs.getInt('photosCount') ?? 0;
      _isPremium = prefs.getBool('isPremium') ?? false;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _processedImage = null;
      });
    }
  }

  Future<void> _removeBackground() async {
    if (_selectedImage == null) return;

    if (!_isPremium && _photosCount >= 6) {
      _showErrorDialog("আজকের ফ্রি সীমা (৬/৬) শেষ! আনলিমিটেড ব্যবহার করতে প্রিমিয়াম নিন।");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.remove.bg/v1.0/removebg'),
      );
      request.headers['X-Api-Key'] = _apiKey;
      request.files.add(await http.MultipartFile.fromPath('image_file', _selectedImage!.path));
      request.fields['size'] = 'auto';

      var response = await request.send();

      if (response.statusCode == 200) {
        var bytes = await response.stream.toBytes();
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/no_bg.png').create();
        await file.writeAsBytes(bytes);

        final prefs = await SharedPreferences.getInstance();
        if (!_isPremium) {
          int newCount = _photosCount + 1;
          await prefs.setInt('photosCount', newCount);
          setState(() {
            _photosCount = newCount;
          });
        }

        setState(() {
          _processedImage = file;
        });
      } else {
        _showErrorDialog("ছবি প্রসেস করা যায়নি! API Key চেক করুন।");
      }
    } catch (e) {
      _showErrorDialog("সমস্যা হয়েছে: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("বিজ্ঞপ্তি"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("ওকে"),
          )
        ],
      ),
    );
  }

  void _showPaymentDialog() {
    final TextEditingController trxController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("👑 প্রিমিয়াম এক্টিভ করুন"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("নগদ (Send Money): 01963320934"),
            const SizedBox(height: 8),
            const Text("মাত্র ৯৯ টাকায় ১ মাস আনলিমিটেড!"),
            const SizedBox(height: 12),
            TextField(
              controller: trxController,
              decoration: const InputDecoration(
                labelText: "TrxID (ট্রানজেকশন আইডি)",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("বাতিল"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (trxController.text.trim().length >= 6) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isPremium', true);
                setState(() {
                  _isPremium = true;
                });
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("অভিনন্দন! আপনার প্রিমিয়াম চালু হয়েছে।")),
                );
              }
            },
            child: const Text("ভেরিফাই"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("MagicCrop AI"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (!_isPremium)
            IconButton(
              icon: const Icon(Icons.star, color: Colors.amber),
              onPressed: _showPaymentDialog,
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const이지ٹسপ্রাইভেট: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isPremium ? Colors.green.shade100 : Colors.amber.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isPremium ? "👑 প্রিমিয়াম ইউজার (Unlimited)" : "📊 ফ্রি লিমিট: $_photosCount/6",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (!_isPremium)
                    ElevatedButton(
                      onPressed: _showPaymentDialog,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                      child: const Text("আপগ্রেড"),
                    )
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _processedImage != null
                  ? Image.file(_processedImage!)
                  : _selectedImage != null
                      ? Image.file(_selectedImage!)
                      : const Center(child: Text("গ্যালারি থেকে ছবি সিলেক্ট করুন")),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo),
                  label: const Text("ছবি বাছুন"),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _removeBackground,
                  icon: const Icon(IconData(0xf01d, fontFamily: 'MaterialIcons')),
                  label: Text(_isLoading ? "প্রসেস হচ্ছে..." : "রিমুভ ব্যাকগ্রাউন্ড"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
