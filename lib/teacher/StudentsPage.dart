import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'ScannerPage.dart';
import 'SessionDetailsPage.dart';

class StudentsPage extends StatelessWidget {
  final String subjectId;
  final String groupId;

  const StudentsPage({
    super.key,
    required this.subjectId,
    required this.groupId,
  });

  // الألوان الموحدة للثيم الاحترافي (Neon Dark Theme)
  final Color deepIndigo = const Color(0xFF0F172A);
  final Color cardColor = const Color(0xFF1E293B);
  final Color neonBlue = const Color(0xFF38BDF8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepIndigo,
      appBar: AppBar(
        title: Text(
          "Sessions: $groupId",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // إضاءة خلفية خفيفة لإعطاء عمق للتصميم
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: neonBlue.withOpacity(0.03),
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  // ترتيب الحصص من الأحدث إلى الأقدم
                  stream: FirebaseFirestore.instance
                      .collection('subjects')
                      .doc(subjectId)
                      .collection('groups')
                      .doc(groupId)
                      .collection('sessions')
                      .orderBy('date', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(color: neonBlue),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildEmptySessions();
                    }

                    var sessions = snapshot.data!.docs;

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        var session = sessions[index];
                        DateTime date;
                        if (session['date'] == null) {
                          date = DateTime.now();
                        } else {
                          date = (session['date'] as Timestamp).toDate();
                        }

                        return _buildSessionCard(context, session.id, date);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          // زر "ابدأ حصة جديدة" بتصميم عائم
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: _buildStartSessionButton(context),
          ),
        ],
      ),
    );
  }

  // تصميم بطاقة الحصة (Session Card)
  Widget _buildSessionCard(
    BuildContext context,
    String sessionId,
    DateTime date,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: neonBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.calendar_today_rounded, color: neonBlue, size: 24),
        ),
        title: const Text(
          "Class Session",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          DateFormat('EEEE, MMM d – HH:mm').format(date),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        // --- الجزء المعدل لإضافة أيقونة التعديل (إعادة الفتح للمتأخرين) ---
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: "Edit attendance (Late students)",
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: neonBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.edit_note_rounded, // أيقونة التعديل المطلوبة
                  color: neonBlue,
                  size: 26,
                ),
              ),
              onPressed: () {
                // الانتقال لصفحة الماسح لنفس الحصة لإضافة المتأخرين
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ScannerPage(
                      subjectId: subjectId,
                      groupId: groupId,
                      sessionId: sessionId,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.3),
              size: 16,
            ),
          ],
        ),
        // ---------------------------------------------------
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SessionDetailsPage(
                subjectId: subjectId,
                groupId: groupId,
                sessionId: sessionId,
              ),
            ),
          );
        },
      ),
    );
  }

  // تصميم الزر "Start New Session"
  Widget _buildStartSessionButton(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(colors: [neonBlue, neonBlue.withOpacity(0.8)]),
        boxShadow: [
          BoxShadow(
            color: neonBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => _createNewSession(context),
        icon: const Icon(Icons.qr_code_scanner_rounded, size: 28),
        label: const Text(
          "START NEW SESSION",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: deepIndigo,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  // واجهة عند عدم وجود حصص
  Widget _buildEmptySessions() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 80,
            color: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 20),
          Text(
            "No sessions recorded yet",
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // دالة إنشاء حصة جديدة
  void _createNewSession(BuildContext context) async {
    DocumentReference sessionRef = await FirebaseFirestore.instance
        .collection('subjects')
        .doc(subjectId)
        .collection('groups')
        .doc(groupId)
        .collection('sessions')
        .add({'date': FieldValue.serverTimestamp(), 'status': 'active'});

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScannerPage(
            subjectId: subjectId,
            groupId: groupId,
            sessionId: sessionRef.id,
          ),
        ),
      );
    }
  }
}
