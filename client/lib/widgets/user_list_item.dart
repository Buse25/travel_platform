import 'package:flutter/material.dart';

class UserListItem extends StatelessWidget {
  final Map<String, dynamic> user;

  const UserListItem({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final username = user["username"]?.toString() ?? "";
    final fullName = user["fullName"]?.toString() ?? "";
    final city = user["city"]?.toString() ?? "";
    final interests = user["interests"] as List<dynamic>? ?? [];

    final displayName = fullName.isNotEmpty ? fullName : username;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          12,
        ), // Rounded corners for modern feel
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0), // Consistent padding for mobile
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Colors.deepPurpleAccent,
              child: Icon(Icons.person, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (city.isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            city,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  if (interests.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: interests.take(3).map((interest) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            interest.toString(),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.deepPurple.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
