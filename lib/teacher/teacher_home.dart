import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projet_fin_etude/main.dart';
import 'package:projet_fin_etude/teacher/GroupsPage.dart';

class TeacherHome extends StatelessWidget {
  final String teacherId;

  const TeacherHome({super.key, required this.teacherId});

  // الألوان الموحدة للثيم الاحترافي
  final Color deepIndigo = const Color(0xFF0F172A);
  final Color cardColor = const Color(0xFF1E293B);
  final Color neonBlue = const Color(0xFF38BDF8);
  final Color errorRed = const Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepIndigo,
      appBar: AppBar(
        title: const Text(
          "MY SUBJECTS",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        // زر تسجيل الخروج
        actions: [
          IconButton(
            icon: Icon(Icons.logout_rounded, color: errorRed),
            onPressed: () => _showLogoutDialog(context),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Stack(
        children: [
          // تأثير التوهج الخلفي
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: neonBlue.withValues(alpha: 0.05),
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('subjects')
                .where('teacherId', isEqualTo: teacherId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: neonBlue),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState();
              }

              var subjects = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                itemCount: subjects.length,
                itemBuilder: (context, index) {
                  var subject = subjects[index].data() as Map<String, dynamic>;
                  var subjectDocId = subjects[index].id;

                  return _buildSubjectCard(context, subject, subjectDocId);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // دالة إظهار تأكيد تسجيل الخروج
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Logout", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Are you sure you want to exit?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: errorRed),
            onPressed: () {
              // الخروج والعودة لصفحة Login
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(
    BuildContext context,
    Map<String, dynamic> subject,
    String subjectId,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GroupsPage(subjectId: subjectId),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: neonBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: neonBlue,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "SUBJECT",
                        style: TextStyle(
                          color: neonBlue,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subject['name'] ?? 'Unknown Subject',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withValues(alpha: 0.2),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 80,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 20),
          const Text(
            "No subjects assigned.",
            style: TextStyle(color: Colors.white38, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
