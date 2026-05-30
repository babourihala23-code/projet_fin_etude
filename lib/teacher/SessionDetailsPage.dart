import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SessionDetailsPage extends StatefulWidget {
  final String subjectId;
  final String groupId;
  final String sessionId;

  const SessionDetailsPage({
    super.key,
    required this.subjectId,
    required this.groupId,
    required this.sessionId,
  });

  @override
  State<SessionDetailsPage> createState() => _SessionDetailsPageState();
}

class _SessionDetailsPageState extends State<SessionDetailsPage> {
  bool _isSyncing = false;

  final Color deepIndigo = const Color(0xFF0F172A);
  final Color cardColor = const Color(0xFF1E293B);
  final Color neonBlue = const Color(0xFF38BDF8);
  final Color successGreen = const Color(0xFF10B981);
  final Color errorRed = const Color(0xFFEF4444);
  final Color orangeAlert = const Color(0xFFFB923C);

  // دالة المزامنة التلقائية (تحدث السجل العام للغيابات)
  Future<void> _autoSyncAbsences(
    List<QueryDocumentSnapshot> allStudents,
    List<String> presentIds,
  ) async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      DocumentSnapshot sessionDoc = await FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subjectId)
          .collection('groups')
          .doc(widget.groupId)
          .collection('sessions')
          .doc(widget.sessionId)
          .get();

      dynamic finalSessionTime = sessionDoc.exists
          ? (sessionDoc.data() as Map<String, dynamic>)['date'] ??
                FieldValue.serverTimestamp()
          : FieldValue.serverTimestamp();

      WriteBatch batch = FirebaseFirestore.instance.batch();

      String cleanedSubjectName = widget.subjectId
          .split('_')
          .where((item) => !RegExp(r'^[0-9]+$').hasMatch(item))
          .join(' ');

      for (var student in allStudents) {
        DocumentReference logRef = FirebaseFirestore.instance
            .collection('attendance_logs')
            .doc("${widget.sessionId}_${student.id}");

        if (presentIds.contains(student.id)) {
          // إذا كان الطالب حاضراً بالـ QR، نحدث حالته في السجل العام لضمان ظهورها في صفحته
          batch.set(logRef, {
            'studentId': student.id,
            'studentName': student['name'],
            'subjectName': cleanedSubjectName,
            'timestamp': finalSessionTime,
            'sessionId': widget.sessionId,
            'status': 'PRESENT',
          }, SetOptions(merge: true));
        } else {
          // إذا كان غائباً، نتأكد أولاً أنه ليس "مبرراً" قبل وسمه كغائب
          DocumentSnapshot existingLog = await logRef.get();
          bool isJustified = false;
          if (existingLog.exists) {
            isJustified =
                (existingLog.data() as Map<String, dynamic>)['status'] ==
                'Justified';
          }

          if (!isJustified) {
            batch.set(logRef, {
              'studentId': student.id,
              'studentName': student['name'],
              'subjectName': cleanedSubjectName,
              'timestamp': finalSessionTime,
              'sessionId': widget.sessionId,
              'status': 'ABSENT',
            }, SetOptions(merge: true));
          }
        }
      }
      await batch.commit();
    } catch (e) {
      debugPrint("❌ Sync Error: $e");
    } finally {
      _isSyncing = false;
    }
  }

  void _showJustifyDialog(String studentId, String studentName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Justify Absence",
          style: TextStyle(color: neonBlue, fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Is the justification for $studentName accepted?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: orangeAlert),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('attendance_logs')
                  .doc("${widget.sessionId}_$studentId")
                  .update({'status': 'Justified'});
              if (mounted) Navigator.pop(context);
            },
            child: const Text(
              "Yes, Accept",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepIndigo,
      appBar: AppBar(
        title: const Text(
          "ATTENDANCE LIST",
          style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('subjects')
            .doc(widget.subjectId)
            .collection('groups')
            .doc(widget.groupId)
            .collection('students')
            .snapshots(),
        builder: (context, snapshotAll) {
          if (!snapshotAll.hasData)
            return Center(child: CircularProgressIndicator(color: neonBlue));

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('subjects')
                .doc(widget.subjectId)
                .collection('groups')
                .doc(widget.groupId)
                .collection('sessions')
                .doc(widget.sessionId)
                .collection('attendance')
                .snapshots(),
            builder: (context, snapshotPresent) {
              if (!snapshotPresent.hasData)
                return Center(
                  child: CircularProgressIndicator(color: neonBlue),
                );

              var presentIds = snapshotPresent.data!.docs
                  .map((doc) => doc.id)
                  .toList();
              var allStudents = snapshotAll.data!.docs;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                _autoSyncAbsences(allStudents, presentIds);
              });

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: allStudents.length,
                itemBuilder: (context, index) {
                  var student = allStudents[index];
                  bool isPresent = presentIds.contains(student.id);

                  return StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('attendance_logs')
                        .doc("${widget.sessionId}_${student.id}")
                        .snapshots(),
                    builder: (context, logSnapshot) {
                      // تحديد الحالة بناءً على الـ QR أولاً ثم السجل
                      String currentStatus = isPresent ? "PRESENT" : "ABSENT";

                      if (logSnapshot.hasData && logSnapshot.data!.exists) {
                        var logData =
                            logSnapshot.data!.data() as Map<String, dynamic>;
                        // إذا كان الطالب ليس حاضراً بالـ QR، نأخذ حالته من السجل (سواء كانت مبررة أو غياب)
                        if (!isPresent) {
                          currentStatus = logData['status'] ?? "ABSENT";
                        }
                      }

                      return _buildStudentTile(
                        student,
                        isPresent,
                        currentStatus,
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStudentTile(
    DocumentSnapshot student,
    bool isPresent,
    String status,
  ) {
    // تحديد اللون بناءً على الحالة النهائية
    Color statusColor = (status == "PRESENT" || isPresent)
        ? successGreen
        : (status == "Justified" ? orangeAlert : errorRed);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        leading: Icon(
          (status == "PRESENT" || isPresent)
              ? Icons.check_circle
              : (status == "Justified"
                    ? Icons.assignment_turned_in_rounded
                    : Icons.cancel),
          color: statusColor,
          size: 30,
        ),
        title: Text(
          student['name'] ?? "Unknown",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          "Status: $status",
          style: TextStyle(color: statusColor.withOpacity(0.8), fontSize: 11),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // إظهار زر التبرير فقط إذا كان الطالب غائباً ولم يتم تبريره بعد
            if (!isPresent && status == "ABSENT")
              IconButton(
                onPressed: () =>
                    _showJustifyDialog(student.id, student['name']),
                icon: Icon(Icons.edit_document, color: orangeAlert, size: 22),
              ),
            const SizedBox(width: 8),
            _buildStatusBadge(status, statusColor),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color badgeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: badgeColor,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }
}
