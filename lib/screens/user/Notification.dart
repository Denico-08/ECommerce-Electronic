import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Notif extends StatelessWidget {
  // List of notifications, each notification is a map with imagePath, title, and comment
  final List<Map<String, dynamic>> notifications;

  const Notif({super.key, required this.notifications});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notification'),
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          final imagePath = notification['imageurl'] ?? 'images/error.jpg';
          final title = notification['name'] ?? 'No Title';
          final comment = notification['description'] ?? 'No Comment';

          return Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                SizedBox(
                  height: 100,
                  width: 100,
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset('images/error.jpg', fit: BoxFit.cover);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.lato(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        softWrap: true,
                        overflow: TextOverflow.ellipsis, // Handle overflow
                      ),
                      const SizedBox(height: 5),
                      const Divider(
                          color: Colors.black,
                          height: 20), // Added height for spacing
                      const SizedBox(height: 5),
                      Text(
                        comment,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis, // Handle overflow
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
