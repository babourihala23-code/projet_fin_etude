import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projet_fin_etude/teacher/StudentsPage.dart';

class GroupsPage extends StatelessWidget {
  final String subjectId;

  const GroupsPage({super.key, required this.subjectId});

  // تعريف الألوان النيلية العميقة
  final Color deepIndigo = const Color(0xFF0F172A);
  final Color cardColor = const Color(0xFF1E293B);
  final Color neonBlue = const Color(0xFF38BDF8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepIndigo,
      appBar: AppBar(
        title: Text(
          "Groups: $subjectId",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // تأثير الإضاءة الخلفية باستخدام withValues
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: neonBlue.withValues(alpha: 0.05), // التعديل هنا
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('subjects')
                .doc(subjectId)
                .collection('groups')
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

              var groups = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  var groupDocId = groups[index].id;
                  return _buildGroupCard(context, groupDocId);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, String groupName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    StudentsPage(subjectId: subjectId, groupId: groupName),
              ),
            );
          },
          child: Ink(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.05),
              ), // التعديل هنا
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2), // التعديل هنا
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  height: 55,
                  width: 55,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        neonBlue.withValues(alpha: 0.2), // التعديل هنا
                        neonBlue.withValues(alpha: 0.05), // التعديل هنا
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: neonBlue.withValues(alpha: 0.3),
                    ), // التعديل هنا
                  ),
                  child: Icon(
                    Icons.groups_3_rounded,
                    color: neonBlue,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Group".toUpperCase(),
                        style: TextStyle(
                          color: neonBlue,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        groupName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.3), // التعديل هنا
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
            Icons.layers_clear_outlined,
            size: 80,
            color: Colors.white.withValues(alpha: 0.1),
          ), // التعديل هنا
          const SizedBox(height: 20),
          Text(
            "No groups available",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 18,
            ), // التعديل هنا
          ),
        ],
      ),
    );
  }
}
