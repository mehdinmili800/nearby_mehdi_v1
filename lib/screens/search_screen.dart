import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:instagram_clone_flutter/screens/profile_screen.dart';
import 'package:instagram_clone_flutter/utils/colors.dart';
import 'package:instagram_clone_flutter/utils/global_variable.dart';
import 'package:instagram_clone_flutter/models/user.dart' as custom;

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<custom.User> users = [];

  @override
  void initState() {
    super.initState();
    setupUsers();
  }

  Future<List<custom.User>> getAllUsers() async {
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('users').get();
    List<custom.User> users = [];
    for (var user in querySnapshot.docs) {
      users.add(custom.User.fromSnap(user));
    }
    return users;
  }

  void setupUsers() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    List<custom.User> allUsers = await getAllUsers();

    String? currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) {
      return;
    }

    allUsers.removeWhere((user) => user.uid == currentUid);

    for (int i = 0; i < allUsers.length; i++) {
      double distance = await Geolocator.distanceBetween(position.latitude,
          position.longitude, allUsers[i].lat, allUsers[i].lng);
      allUsers[i] = custom.User(
        username: allUsers[i].username,
        uid: allUsers[i].uid,
        photoUrl: allUsers[i].photoUrl,
        email: allUsers[i].email,
        bio: allUsers[i].bio,
        followers: allUsers[i].followers,
        following: allUsers[i].following,
        lat: allUsers[i].lat,
        lng: allUsers[i].lng,
        distance: distance,
      );
    }

    allUsers.sort((a, b) => a.distance.compareTo(b.distance));

    setState(() {
      users = allUsers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nearby Users'),
      ),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              leading: SizedBox(
                width: 100,
                height: 100,
                child: CachedNetworkImage(
                  imageUrl: users[index].photoUrl,
                  placeholder: (context, url) => CircularProgressIndicator(),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                ),
              ),
              title: Text(users[index].username),
              subtitle: Text(
                  '${users[index].distance.toStringAsFixed(2)} meters away'),
              onTap: () {
                Get.to(() => ProfileScreen(
                      uid: users[index].uid,
                    ));
              },
            ),
          );
        },
      ),
    );
  }
}
