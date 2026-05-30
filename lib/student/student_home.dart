import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:projet_fin_etude/main.dart';

class StudentHome extends StatefulWidget {
  final String studentId;
  const StudentHome({super.key, required this.studentId});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 1;

  // الألوان المعتمدة
  final Color deepIndigo = const Color(0xFF0F172A);
  final Color neonBlue = const Color(0xFF38BDF8);
  final Color errorRed = const Color(0xFFEF4444);
  final Color orangeAlert = const Color(0xFFFB923C);
  final Color cardColor = const Color(0xFF1E293B);

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      _buildProfilePage(),
      _buildQRPage(),
      _buildAttendanceHistory(),
    ];

    return Scaffold(
      backgroundColor: deepIndigo,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: neonBlue.withOpacity(0.05),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: _pages[_currentIndex],
          ),
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              icon: Icon(
                Icons.logout_rounded,
                color: errorRed.withOpacity(0.8),
                size: 28,
              ),
              onPressed: () => _showLogoutDialog(context),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildLiveNav(),
    );
  }

  // --- 1. صفحة الملف الشخصي ---
  Widget _buildProfilePage() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('registrationNumber', isEqualTo: widget.studentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: neonBlue));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No Profile Found",
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        var data = snapshot.data!.docs.first.data() as Map<String, dynamic>;

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              backgroundColor: Colors.transparent,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: neonBlue.withOpacity(0.1),
                      child: Icon(Icons.person, size: 50, color: neonBlue),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "${data['firstName']} ${data['lastName']}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      data['speciality'] ?? "Student",
                      style: TextStyle(color: neonBlue, letterSpacing: 1.2),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _liveInfoTile(
                    "Registration ID",
                    data['registrationNumber'],
                    Icons.badge_outlined,
                  ),
                  _liveInfoTile(
                    "Faculty",
                    data['faculty'],
                    Icons.account_balance_outlined,
                  ),
                  _liveInfoTile(
                    "University",
                    data['university'],
                    Icons.business_outlined,
                  ),
                  _liveInfoTile(
                    "Year",
                    data['year'],
                    Icons.calendar_today_outlined,
                  ),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- 2. صفحة الـ QR ---
  Widget _buildQRPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "DIGITAL ATTENDANCE PASS",
            style: TextStyle(
              color: neonBlue,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          ScaleTransition(
            scale: Tween(begin: 1.0, end: 1.05).animate(
              CurvedAnimation(
                parent: _pulseController,
                curve: Curves.easeInOut,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: neonBlue.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: QrImageView(
                data: widget.studentId,
                version: QrVersions.auto,
                size: 220,
              ),
            ),
          ),
          const SizedBox(height: 30),
          Text(
            "ID: ${widget.studentId}",
            style: const TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // --- 3. صفحة سجل الغيابات ---
  Widget _buildAttendanceHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 80, left: 25, bottom: 20),
          child: Text(
            "Attendance History",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('attendance_logs')
                .where('studentId', isEqualTo: widget.studentId)
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

              var docs = snapshot.data!.docs.where((doc) {
                String status =
                    (doc.data() as Map<String, dynamic>)['status'] ?? "";
                return status.toUpperCase() == "ABSENT" ||
                    status.toLowerCase() == "justified";
              }).toList();

              docs.sort((a, b) {
                Timestamp t1 = (a.data() as Map<String, dynamic>)['timestamp'];
                Timestamp t2 = (b.data() as Map<String, dynamic>)['timestamp'];
                return t2.compareTo(t1);
              });

              if (docs.isEmpty) return _buildEmptyState();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  var log = docs[index].data() as Map<String, dynamic>;
                  return _attendanceTile(log);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _attendanceTile(Map<String, dynamic> log) {
    DateTime date = (log['timestamp'] as Timestamp).toDate();
    String status = log['status'] ?? "ABSENT";

    bool isJustified = status.toLowerCase() == "justified";
    Color statusColor = isJustified ? orangeAlert : errorRed;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isJustified
                  ? Icons.assignment_turned_in_rounded
                  : Icons.event_busy_rounded,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log['subjectName'] ?? "Subject",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, dd MMM yyyy - HH:mm').format(date),
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---
  Widget _liveInfoTile(String title, String? value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: neonBlue, size: 24),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              Text(
                value ?? "-",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.verified_user_rounded,
            size: 80,
            color: neonBlue.withOpacity(0.1),
          ),
          const SizedBox(height: 20),
          const Text(
            "No absences recorded",
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 30),
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.9),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.person_rounded, 0),
          _navItem(Icons.qr_code_2_rounded, 1),
          _navItem(Icons.history_rounded, 2),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, int index) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? neonBlue : Colors.white54, size: 28),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: neonBlue,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Logout", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Are you sure you want to logout?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: errorRed),
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
            ),
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
