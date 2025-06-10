import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    String currentUserUID = FirebaseAuth.instance.currentUser!.uid;


    print(currentUserUID);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome to Smart Locks"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Personalized Greeting
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUserUID)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading user data'));
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(child: Text('User data not found'));
                  }

                  String userName = snapshot.data?.get('name') ?? 'User';

                  // User one = User.from

                  return Text(
                    "Welcome, $userName! Here’s an overview of your locks today.",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),

            // Quick Stats
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Locks')
                    .where('accessible_user', isEqualTo: currentUserUID)
                    .snapshots(),
                builder: (context, snapshot) {
                  print(snapshot.data);
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading data'));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No locks found'));
                  }

                  var data = snapshot.data!.docs;
                  int totalLocks = data.length;
                  int unlockedLocks = data.where((lock) => lock['lock status'] == 'Unlocked').length;

                  return Row(
                    children: [
                      Expanded(
                        child: Card(
                          color: Colors.blue[50],
                          child: ListTile(
                            title: const Text('Total Locks'),
                            trailing: Text('$totalLocks'),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Card(
                          color: Colors.green[50],
                          child: ListTile(
                            title: const Text('Unlocked Locks'),
                            trailing: Text('$unlockedLocks'),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Lock Status Overview
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Lock Status Overview",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('Locks')
                        .where('accessible_user', isEqualTo: currentUserUID) // Filter by current user
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(child: Text('Error loading data'));
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No locks found'));
                      }

                      var data = snapshot.data!.docs;

                      return Column(
                        children: data.map((lock) {
                          var lockName = lock['lock name'] ?? 'Unknown Lock';
                          var status = lock['lock status'] ?? 'Unknown'; // Ensure we use 'lock status'

                          return ListTile(
                            title: Text(lockName),
                            subtitle: Text('Status: $status'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.lock),
                                  onPressed: () async {
                                    try {
                                      await FirebaseFirestore.instance
                                          .collection('Locks')
                                          .doc(lock.id)
                                          .update({'lock status': 'Locked'}); // Update to 'Locked'
                                      print("Locked: ${lock.id}");
                                    } catch (e) {
                                      print("Error locking: $e");
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.lock_open),
                                  onPressed: () async {
                                    try {
                                      await FirebaseFirestore.instance
                                          .collection('Locks')
                                          .doc(lock.id)
                                          .update({'lock status': 'Unlocked'}); // Update to 'Unlocked'
                                      print("Unlocked: ${lock.id}");
                                    } catch (e) {
                                      print("Error unlocking: $e");
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),

            // // Security Alerts
            // Padding(
            //   padding: const EdgeInsets.all(16.0),
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       const Text(
            //         "Security Alerts",
            //         style: TextStyle(
            //           fontSize: 18,
            //           fontWeight: FontWeight.bold,
            //         ),
            //       ),
            //       const SizedBox(height: 10),
            //       StreamBuilder<QuerySnapshot>(
            //         stream: FirebaseFirestore.instance
            //             .collection('Locks')
            //             .where('accessible_user', isEqualTo: currentUserUID)
            //             .where('securityAlert', isEqualTo: true) // Filtering locks with alerts
            //             .snapshots(),
            //         builder: (context, snapshot) {
            //           if (snapshot.connectionState == ConnectionState.waiting) {
            //             return const Center(child: CircularProgressIndicator());
            //           }
            //           if (snapshot.hasError) {
            //             return const Center(child: Text('Error loading data'));
            //           }

            //           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            //             return const Center(child: Text('No security alerts'));
            //           }

            //           var data = snapshot.data!.docs;

            //           return Column(
            //             children: data.map((lock) {
            //               var lockName = lock['lockName'] ?? 'Unknown Lock';

            //               return ListTile(
            //                 title: Text(lockName),
            //                 subtitle: const Text('Security Alert!'),
            //                 leading: const Icon(Icons.warning, color: Colors.red),
            //               );
            //             }).toList(),
            //           );
            //         },
            //       ),
            //     ],
            //   ),
            // ),


            // Lock/Unlock All Buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        // Fetch all locks for the current user
                        var locksQuery = await FirebaseFirestore.instance
                            .collection('Locks')
                            .where('accessible_user', isEqualTo: currentUserUID)
                            .get();

                        // Debug: Check the number of locks fetched
                        print("Locks found for locking: ${locksQuery.docs.length}");

                        // Update status to 'locked' for all locks
                        for (var lock in locksQuery.docs) {
                          await FirebaseFirestore.instance
                              .collection('Locks')
                              .doc(lock.id)
                              .update({'lock status': 'Locked'});

                          // Debug: Confirm each lock is updated
                          print("Locked: ${lock.id}");
                        }

                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('All locks have been locked!')),
                        );
                      } catch (e) {
                        // Show error message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error locking all locks: $e')),
                        );
                      }
                    },
                    child: const Text('Lock All'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        // Fetch all locks for the current user
                        var locksQuery = await FirebaseFirestore.instance
                            .collection('Locks')
                            .where('accessible_user', isEqualTo: currentUserUID)
                            .get();

                        // Debug: Check the number of locks fetched
                        print("Locks found for unlocking: ${locksQuery.docs.length}");

                        // Update status to 'unlocked' for all locks
                        for (var lock in locksQuery.docs) {
                          await FirebaseFirestore.instance
                              .collection('Locks')
                              .doc(lock.id)
                              .update({'lock status': 'Unlocked'});

                          // Debug: Confirm each lock is updated
                          print("Unlocked: ${lock.id}");
                        }

                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('All locks have been unlocked!')),
                        );
                      } catch (e) {
                        // Show error message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error unlocking all locks: $e')),
                        );
                      }
                    },
                    child: const Text('Unlock All'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
