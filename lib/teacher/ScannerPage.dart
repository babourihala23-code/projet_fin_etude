import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScannerPage extends StatefulWidget {
  final String subjectId;
  final String groupId;
  final String sessionId;

  const ScannerPage({
    super.key,
    required this.subjectId,
    required this.groupId,
    required this.sessionId,
  });

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  bool isScanCompleted = false;

  final Color deepIndigo = const Color(0xFF0F172A);
  final Color neonBlue = const Color(0xFF38BDF8);
  final Color warningRed = const Color(0xFFEF4444);
  final Color cardColor = const Color(0xFF1E293B);

  void _markAsPresent(String studentId) async {
    if (isScanCompleted) return;
    setState(() => isScanCompleted = true);

    try {
      // 1. جلب بيانات الطالب أولاً لعرضها في البطاقة
      var studentDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('registrationNumber', isEqualTo: studentId)
          .get();

      if (studentDoc.docs.isNotEmpty) {
        var userData = studentDoc.docs.first.data();

        // 2. تحديث الحضور في قاعدة البيانات
        await FirebaseFirestore.instance
            .collection('subjects')
            .doc(widget.subjectId)
            .collection('groups')
            .doc(widget.groupId)
            .collection('sessions')
            .doc(widget.sessionId)
            .collection('attendance')
            .doc(studentId)
            .set({
              'studentId': studentId,
              'status': 'present',
              'arrivalTime': FieldValue.serverTimestamp(),
            });

        // 3. عرض البطاقة المنبثقة
        if (mounted) {
          _showStudentDialog(userData);
        }
      } else {
        // إذا لم يوجد الطالب في قاعدة البيانات
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Student Not Found!")));
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    // تأخير بسيط قبل السماح بمسح الكود التالي
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) setState(() => isScanCompleted = false);
  }

  void _showStudentDialog(Map<String, dynamic> userData) {
    showDialog(
      context: context,
      barrierDismissible: false, // يجب إغلاقها يدوياً أو تنغلق تلقائياً
      builder: (context) {
        // إغلاق تلقائي بعد ثانيتين
        Future.delayed(const Duration(seconds: 2), () {
          if (Navigator.canPop(context)) Navigator.pop(context);
        });

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: neonBlue.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: neonBlue.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.greenAccent,
                  size: 60,
                ),
                const SizedBox(height: 20),
                // صورة الطالب (افتراضية أو من قاعدة البيانات)
                CircleAvatar(
                  radius: 50,
                  backgroundColor: neonBlue.withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "${userData['firstName']} ${userData['lastName']}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "ID: ${userData['registrationNumber']}",
                  style: TextStyle(
                    color: neonBlue,
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  userData['speciality'] ?? "Student",
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 20),
                const Text(
                  "MARKED PRESENT ✅",
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepIndigo,
      appBar: AppBar(
        title: const Text(
          "QR SCANNER",
          style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: MobileScannerController(
              detectionSpeed: DetectionSpeed.noDuplicates,
              facing: CameraFacing.back,
            ),
            onDetect: (capture) {
              for (final barcode in capture.barcodes) {
                if (barcode.rawValue != null) _markAsPresent(barcode.rawValue!);
              }
            },
          ),
          _buildScannerOverlay(context),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: _buildFinishButton(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay(BuildContext context) {
    return Stack(
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            deepIndigo.withValues(alpha: 0.7),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  height: 250,
                  width: 250,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: Container(
            height: 250,
            width: 250,
            decoration: BoxDecoration(
              border: Border.all(color: neonBlue, width: 3),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: neonBlue.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
        const Align(
          alignment: Alignment.center,
          child: Padding(
            padding: EdgeInsets.only(top: 320),
            child: Text(
              "Align QR code within the frame",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinishButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: warningRed.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.stop_circle_rounded),
        label: const Text("FINISH SESSION"),
        style: ElevatedButton.styleFrom(
          backgroundColor: warningRed,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }
}
