import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:smartparcelbox/models/deviceIdmodel.dart';
import 'package:smartparcelbox/models/logImagemodel.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart' as img;
import 'package:smartparcelbox/screens/home/home.dart';
import '../../service.dart';

class LockerScreen extends StatefulWidget {
  final String log_id;
  final String device_id;
  const LockerScreen({
    Key? key,
    required this.log_id,
    required this.device_id,
  }) : super(key: key);

  @override
  State<LockerScreen> createState() => _LockerScreenState();
}

class _LockerScreenState extends State<LockerScreen> {
  ImageNameModel? _imageNameModel;
  String namefile = '';
  File? _image;
  var imagePicker;
  bool isShowLocker = false;
  Timer? _timer;
  var _start = 60.obs;
  DeviceIdModel? _deviceIdModel;
  CameraController? controller_camera;
  XFile? pictureFile;

  void getImage() async {
    PickedFile? pickedFile = await ImagePicker().getImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
    );
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      await uploadImage();
      // getNameFile();
      // uploadImage();
    }
  }
  // Future getImage() async {
  //   XFile? image = pictureFile;
  //   if (image != null) {
  //     setState(() {
  //       _image = File(image.path);
  //     });
  //     await uploadImage();
  //     // getNameFile();
  //     // uploadImage();
  //   }
  // }

  void getNameFile() async {
    var url = Uri.parse(
        connect().url + 'api/device/log/log_imgreceive/${widget.log_id}');
    print(url);
    var response = await http.put(url);
    if (response.statusCode == 200) {
      setState(() {
        _imageNameModel = imageNameModelFromJson(response.body);
      });
      print(jsonEncode(_imageNameModel));
      print('filename ===> ${_imageNameModel!.data.message.file}');
      var str = _imageNameModel!.data.message.file.toString();
      print(str);
      print('//');
      print(str.substring(0, str.indexOf('.png')));
      setState(() {
        namefile = str.substring(0, str.indexOf('.png'));
      });
    }
  }

  // void uploadImage() async {
  //   try {

  //     if (_image != null) {
  //       print('namefile ===> ### $namefile');
  //       var postImageUri =
  //           Uri.parse(connect().url + "upload-images/upload-image/${namefile}");
  //       print("URI ===> ## $postImageUri");
  //       print('filepath ===> ### ${_image!.path}');
  //       try {
  //         // var postUri = Uri.parse(
  //         //     connect().url + "upload-images/upload-image/${namefile}");
  //         http.MultipartRequest request =
  //             new http.MultipartRequest("POST", postImageUri);
  //         http.MultipartFile multipartFile = await http.MultipartFile.fromPath(
  //           'file',
  //           _image!.path,
  //           contentType: MediaType(
  //             'image',
  //             'png',
  //           ),
  //         );
  //         request.files.add(multipartFile);
  //         http.StreamedResponse response = await request.send();
  //         if (response.statusCode == 200) {
  //           print('?????????????????????????????????????????????????????????');
  //           openLocker();
  //         } else {
  //           print(response.statusCode);
  //           print('??????????????????????????????????????????????????????????????????');
  //         }

  //         //update_namefile();
  //       } catch (err) {
  //         // tar_widget().showInSnackBar('??????????????????????????????????????????????????????????????????????????????', Colors.white,
  //         //     _scaffoldKey, Colors.red, 4);
  //       }
  //     } else {
  //       print('_image ===> ### null');
  //       _showDialog(context);
  //     }
  //   } catch (e) {
  //     print('error ===> $e');
  //   }
  // }
  uploadImage() async {
    try {
      if (_image != null) {
        img.Image? imageTemp = img.decodeImage(_image!.readAsBytesSync());
        img.Image resizedImg = img.copyResize(imageTemp!, height: 500);

        var request = new http.MultipartRequest(
            'POST',
            Uri.parse(
                connect().url + "upload-images/upload-image/${namefile}"));
        var multipartFile = new http.MultipartFile.fromBytes(
          'file',
          img.encodeJpg(resizedImg),
          filename: 'resized_image.jpg',
          contentType: MediaType.parse('image/jpeg'),
        );

        request.files.add(multipartFile);
        var response = await request.send();
        print(response.statusCode);
        if (response.statusCode == 200) {
          print('?????????????????????????????????????????????????????????');
          print(response);
          openLocker();
        } else {
          print(response.statusCode);
          print('??????????????????????????????????????????????????????????????????');
        }
        response.stream.transform(utf8.decoder).listen((value) {
          print(value);
        });
      }
    } catch (e) {
      print(e);
    }
  }

  void openLocker() async {
    try {
      var device_id = await widget.device_id;
      print('device_id ===> ## $device_id');
      var putOpenlocker = Uri.parse(
          connect().url + "api/device/device/managerdevice/${device_id}");
      var body = {
        "device_success": "0",
        "device_status": "0",
        "device_check": "3"
      };
      print(body);
      var response = await http.put(putOpenlocker, body: body);
      if (response.statusCode == 200) {
        print(jsonEncode(response.body));
        print('???????????????????????????locker???????????????????????????????????????');
        getDeviceStatus();
        setState(() {
          isShowLocker = true;
        });
        isShowLocker == true ? _showDialogOpenLocker(context) : null;
      } else {
        print(response.statusCode);
        print('???????????????????????????locker ???????????????????????????');
      }
    } catch (e) {
      print(e);
    }
  }

  // void getDeviceStatus() async {
  //   try {
  //     var device_id = await widget.device_id;
  //     print('device_id ===> ## $device_id');
  //     var putOpenlocker =
  //         Uri.parse(connect().url + "api/device/group/device_id/${device_id}");
  //     Timer.periodic(new Duration(seconds: 5), (timer) {
  //       print('getDeviceStatus'+timer.tick.toString());
  //     });
  //   } catch (e) {
  //     print(e);
  //   }
  // }

  void getDeviceStatus() async {
    try {
      var device_id = await widget.device_id;
      print('device_id ===> ## $device_id');
      var getdeviceID =
          Uri.parse(connect().url + "api/device/group/device_id/${device_id}");

      var oneSec = const Duration(seconds: 1);
      _timer = new Timer.periodic(
        oneSec,
        (Timer timer) async {
          if (_start == 0) {
            setState(() {
              timer.cancel();
            });
            Navigator.pop(context);
            Navigator.pop(context);
          } else {
            setState(() {
              _start--;
            });
            print('getDeviceStatus ===> ### $_start');
            var response = await http.get(getdeviceID);
            if (response.statusCode == 200) {
              setState(() {
                _deviceIdModel = deviceIdModelFromJson(response.body);
              });
              print(_deviceIdModel);
              print(
                  'device_success ===> ${_deviceIdModel!.data.message.deviceSuccess}');
              if (_deviceIdModel!.data.message.deviceStatus.toString() != '0') {
                _timer!.cancel();
                sendLine();
              }
            } else {
              print('error ===> ${response.statusCode}');
              Navigator.pop(context);
              Navigator.pop(context);
            }
          }
        },
      );
    } catch (e) {
      print(e);
    }
  }

  void sendLine() async {
    var device_id = await widget.device_id;
    var urlsendline =
        Uri.parse(connect().url + "api/linebot/send/step/2/${device_id}");
    var response = await http.get(urlsendline);
    if (response.statusCode == 200) {
      print('sendLine success');
      // Navigator.pop(context);
      // Navigator.pop(context);
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => HomeScreen()));
      Fluttertoast.showToast(
          msg: "?????????????????????????????????????????????????????????",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
    } else {
      print('error ===> ${response.statusCode}');
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getNameFile();
    imagePicker = ImagePicker();
  }

  @override
  void dispose() {
    if (_timer != null) {
      _timer!.cancel();
    }
    controller_camera!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.black54,
        ),
        title: Text(
          '???????????????????????????',
          style: TextStyle(color: Colors.black54),
        ),
        centerTitle: true,
        elevation: 3,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: size.height * 0.01,
              ),
              const Text(
                '????????????????????????????????????',
              ),
              SizedBox(
                height: size.height * 0.02,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Container(
                    color: Colors.green[50],
                    width: size.width * 0.8,
                    height: size.height * 0.5,
                    child: _image == null
                        ? const Center(
                            child: Text(
                            '???????????????????????????????????????????????????????????????',
                            style: TextStyle(fontSize: 20),
                          ))
                        : Image.file(_image!),
                  ),
                ),
              ),
              // Padding(
              //   padding: const EdgeInsets.all(8.0),
              //   child: Center(
              //     child: Container(
              //       color: Colors.green[50],
              //       width: size.width * 0.8,
              //       height: size.height * 0.5,
              //       child: _image == null
              //           ? CameraPreview(controller_camera!)
              //           : Image.file(_image!),
              //     ),
              //   ),
              // ),
              SizedBox(height: size.height * 0.02),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green[100]!,
                      blurRadius: 2.0,
                      spreadRadius: 0.0,
                      offset: Offset(0, 3.0), // shadow direction: bottom right
                    )
                  ],
                ),
                width: size.width * 0.7,
                child: FlatButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  padding: EdgeInsets.all(10),
                  color: Colors.green[300],
                  textColor: Colors.white,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "?????????????????????",
                        style: TextStyle(
                          fontSize: 18,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Icon(Icons.camera_alt)
                    ],
                  ),
                  onPressed: () async {
                    // print('?????????????????????');
                    // pictureFile = await controller_camera!.takePicture();
                    // setState(() {});
                    getImage();
                  },
                ),
              ),
              SizedBox(height: size.height * 0.01),
            ],
          ),
        ),
      ),
    );
  }

  _showDialog(context) async {
    Alert(context: context, title: "????????????????????????????????????", buttons: [
      DialogButton(
        color: Colors.green[300],
        onPressed: () async {
          Navigator.pop(context);
          Navigator.pop(context);
        },
        child: Text(
          "????????????",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      )
    ]).show();
  }

  _showDialogOpenLocker(context) async {
    Alert(
        context: context,
        title: "??????????????????????????????????????????????????????????????????",
        content: Column(
          children: [
            Obx(() => Text('??????????????????????????????????????? ${_start} ??????????????????')),
            const Text('?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????'),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: const Icon(
                Icons.lock_open,
                size: 80,
              ),
            ),
          ],
        ),
        buttons: [
          DialogButton(
            color: Colors.green[300],
            onPressed: () async {
              Navigator.pop(context);
              _timer!.cancel();
            },
            child: Text(
              "????????????",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          )
        ]).show();
  }
}
