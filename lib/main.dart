import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const DriveLicenseCheck());
}

class DriveLicenseCheck extends StatelessWidget {
  const DriveLicenseCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: DriveLicenseCheckApp(),
    );
  }
}

class DriveLicenseCheckApp extends StatefulWidget {
  const DriveLicenseCheckApp({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _DriveLicenseCheckAppState createState() => _DriveLicenseCheckAppState();
}

class RemainingDaysWidget extends StatelessWidget {
  final String expiredDate;

  const RemainingDaysWidget({
    super.key,
    required this.expiredDate,
  });

  String convertDateFormat(String inputDate) {
    List<String> parts = inputDate.split('-');

    String year = parts[2];
    String month = parts[1];
    String day = parts[0];

    return '$year-$month-$day';
  }

  String formatDate(String date) {
    List<String> parts = date.split('/');
    String formattedDate = parts.join('-');
    return formattedDate;
  }

  int calculateRemainingDays() {
    DateTime expiredDateTime =
        DateTime.parse(convertDateFormat(formatDate(expiredDate)));

    DateTime now = DateTime.now();

    if (expiredDateTime.isBefore(now)) {
      Duration difference = now.difference(expiredDateTime);
      return difference.inDays;
    } else {
      Duration difference = expiredDateTime.difference(now);
      return difference.inDays;
    }
  }

  @override
  Widget build(BuildContext context) {
    int remainingDays = calculateRemainingDays();

    String text;
    if (remainingDays == 0) {
      text = 'Today is the expiration date.';
    } else if (remainingDays > 0) {
      text = 'There are only $remainingDays days left before it expires';
    } else {
      text = 'It has expired for ${remainingDays.abs()} days';
    }

    return Text(text);
  }
}

class _DriveLicenseCheckAppState extends State<DriveLicenseCheckApp> {
  bool imageSelected = false;
  bool isLoading = false;
  File _image = File('images/blank.png');
  final ImagePicker picker = ImagePicker();
  Map<String, dynamic> informationLicense = {};

  Future getImageFromGallery() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        imageSelected = true;
      }
    });
  }

  Future getImageFromCamera() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        imageSelected = true;
      }
    });
  }

  Future showOptions() async {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            child: const Text('Photo Gallery'),
            onPressed: () {
              Navigator.of(context).pop();
              getImageFromGallery();
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Camera'),
            onPressed: () {
              Navigator.of(context).pop();
              getImageFromCamera();
            },
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> checkLicense(File imageFile) async {
    final url = Uri.parse(
        'http://34.123.173.103:8080/api/v1/check-information-license');
    try {
      var request = http.MultipartRequest('POST', url);
      var multipartFile =
          await http.MultipartFile.fromPath('image', imageFile.path);
      request.files.add(multipartFile);
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        setState(() {});
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to upload image. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> _handleCheckLicense() async {
    try {
      setState(() {
        informationLicense = {};
        isLoading = true;
      });
      var result = await checkLicense(_image);
      var data = result['data'];
      setState(() {
        informationLicense = data;
        isLoading = false;
      });
    } catch (error) {
      throw ('Error: $error');
    }
  }

  Map<String, String> keyMap = {
    'id': 'ID',
    'type': 'Type',
    'full_name': 'Full Name',
    'city': 'City',
    'birth_day': 'Birth Day',
    'blood_type': 'Blood Type',
    'gender': 'Gender',
    'address': 'Address',
    'work': 'Work',
    'domicile': 'Domicile',
    'expired': 'Expired',
  };

  String getBetterKeyName(String key) {
    return keyMap[key] ?? key;
  }

  List<String> keyOrder = [
    'id',
    'type',
    'full_name',
    'city',
    'birth_day',
    'blood_type',
    'gender',
    'address',
    'work',
    'domicile',
    'expired',
  ];

  Widget buildLicenseDataList(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: keyOrder.map((key) {
        final entryValue = data[key];
        if (entryValue != null) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120, // Lebar untuk nama key
                  child: Text(
                    '${getBetterKeyName(key)}:',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(entryValue.toString()),
                ),
              ],
            ),
          );
        } else {
          return const SizedBox
              .shrink(); // Menghilangkan widget jika nilai entry null
        }
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drive License Check'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(
                    Icons.image,
                    size: 20.0,
                  ),
                  onPressed: showOptions,
                  label: const Text('Select Image Card License Drive'),
                ),
              ),
              const SizedBox(height: 20.0),
              Center(
                  child: SizedBox(
                width: double.infinity,
                height: 230,
                child: imageSelected
                    ? Image.file(
                        _image,
                        fit: BoxFit.fill,
                      )
                    : const Text(
                        "No images have been selected yet",
                        textAlign: TextAlign.center,
                      ),
              )),
              const SizedBox(height: 20.0),
              Container(
                child: imageSelected
                    ? SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: isLoading
                                ? const Icon(Icons.hourglass_top)
                                : const Icon(Icons.check),
                          ),
                          onPressed: isLoading ? null : _handleCheckLicense,
                          label: Text(isLoading ? 'Loading...' : 'Check Card'),
                        ),
                      )
                    : Container(),
              ),
              const SizedBox(height: 20.0),
              if (informationLicense.isNotEmpty)
                const Text("Card Information :",
                    textAlign: TextAlign.start,
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10.0),
              if (informationLicense != {})
                buildLicenseDataList(informationLicense),
              const SizedBox(height: 20.0),
              if (informationLicense.isNotEmpty)
                const Text(
                  "Date Expired Detail : ",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.start,
                ),
              const SizedBox(height: 10.0),
              if (informationLicense.isNotEmpty)
                RemainingDaysWidget(
                  expiredDate: informationLicense['expired'],
                ),
              const SizedBox(height: 20.0),
            ],
          ),
        ),
      ),
    );
  }
}
