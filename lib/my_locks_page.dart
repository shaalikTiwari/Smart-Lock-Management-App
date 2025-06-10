import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home_page.dart';

class MyLocksPage extends StatelessWidget {
  const MyLocksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Locks"),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Locks')
              .where('accessible_user', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "No locks assigned to you.",
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        _showAddLockDialog(context);
                      },
                      child: const Text("Add Lock"),
                    ),
                  ],
                ),
              );
            }

            final locks = snapshot.data!.docs;
            return ListView.builder(
              itemCount: locks.length,
              itemBuilder: (context, index) {
                final lock = locks[index];
                final lockId = lock.id;
                final lockStatus = lock['lock status'] ?? 'Unknown';

                return ListTile(
                  title: Text(lock['lock name'] ?? 'Unnamed Lock'),
                  subtitle: Text("Status: $lockStatus"),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      Icon(
                        lockStatus == "Unlocked" ? Icons.lock_open : Icons.lock,
                        color: lockStatus == "Unlocked" ? Colors.green : Colors.red,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _confirmDeleteLock(context, lockId);
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    _navigateToLockDetails(context, lock);
                  },
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddLockDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddLockDialog(BuildContext context) {
    final TextEditingController lockNameController = TextEditingController();
    final auth = FirebaseAuth.instance;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Add New Lock"),
          content: TextField(
            controller: lockNameController,
            decoration: const InputDecoration(
              hintText: "Enter lock name",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final String lockName = lockNameController.text.trim();
                final String? userUID = auth.currentUser?.uid;

                if (lockName.isNotEmpty && userUID != null) {
                  try {
                    final newLockRef = FirebaseFirestore.instance.collection('Locks').doc();
                    await newLockRef.set({
                      'lock name': lockName,
                      'lock status': 'Unlocked',
                      'accessible_user': userUID,
                      'access locks': [],
                    });

                    await FirebaseFirestore.instance.collection('Users').doc(userUID).update({
                      'assigned lock': newLockRef.id,
                    });

                    lockNameController.clear();
                    Navigator.pop(context);

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Lock '$lockName' added successfully!"),
                        ),
                      );
                    });
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error adding lock: $e")),
                    );
                  }
                }
              },
              child: const Text("Add Lock"),
            ),
          ],
        );
      },
    );
  }

  void _navigateToLockDetails(BuildContext context, QueryDocumentSnapshot lock) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LockDetailsPage(lock: lock),
      ),
    );
  }

  void _confirmDeleteLock(BuildContext context, String lockId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Lock"),
          content: const Text("Are you sure you want to delete this lock?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                await _deleteLock(context, lockId);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteLock(BuildContext context, String lockId) async {
    try {
      await FirebaseFirestore.instance.collection('Locks').doc(lockId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lock deleted successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting lock: $e")),
      );
    }
  }
}
