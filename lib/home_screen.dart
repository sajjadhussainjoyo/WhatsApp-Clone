import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth/login_screen.dart';
import 'screens/chat_screen.dart';

class _Contact {
  final String name;
  final String preview;
  final String time;
  final String image;
  final Color accent;

  const _Contact({
    required this.name,
    required this.preview,
    required this.time,
    required this.image,
    required this.accent,
  });
}

const _contacts = [
  _Contact(
      name: 'Mohsin',
      preview: 'How was your day today?',
      time: '5:00 AM',
      image: 'assets/images/mohsin.jpg.jpeg',
      accent: Color(0xff27ae60)),
  _Contact(
      name: 'Umer',
      preview: 'See you tomorrow',
      time: '4:42 AM',
      image: 'assets/images/umer.jpg.jpeg',
      accent: Color(0xfff39c12)),
  _Contact(
      name: 'Hasan',
      preview: 'I will be there in 10 minutes',
      time: '3:18 AM',
      image: 'assets/images/hasan.jpeg',
      accent: Color(0xff2980b9)),
  _Contact(
      name: 'Aqil',
      preview: 'Let us catch up soon',
      time: 'Yesterday',
      image: 'assets/images/mohsin.jpg.jpeg',
      accent: Color(0xff8e44ad)),
  _Contact(
      name: 'Bilal Ahmed',
      preview: 'Thanks!',
      time: 'Yesterday',
      image: 'assets/images/umer.jpg.jpeg',
      accent: Color(0xff16a085)),
  _Contact(
      name: 'Mubeen Ahmed',
      preview: 'Voice message',
      time: 'Monday',
      image: 'assets/images/hasan.jpeg',
      accent: Color(0xffd35400)),
  _Contact(
      name: 'Hamza Ali',
      preview: 'On my way',
      time: 'Monday',
      image: 'assets/images/mohsin.jpg.jpeg',
      accent: Color(0xff2c3e50)),
  _Contact(
      name: 'Zakar Ali',
      preview: 'That sounds great',
      time: 'Sunday',
      image: 'assets/images/umer.jpg.jpeg',
      accent: Color(0xffc0392b)),
  _Contact(
      name: 'Danish Raza',
      preview: 'Missed call',
      time: 'Sunday',
      image: 'assets/images/hasan.jpeg',
      accent: Color(0xff7f8c8d)),
  _Contact(
      name: 'Haris',
      preview: 'Have a nice day',
      time: 'Saturday',
      image: 'assets/images/mohsin.jpg.jpeg',
      accent: Color(0xff1abc9c)),
  _Contact(
      name: 'Usman Tariq',
      preview: 'Document',
      time: 'Friday',
      image: 'assets/images/umer.jpg.jpeg',
      accent: Color(0xff34495e)),
  _Contact(
      name: 'Malik Shahbaz',
      preview: 'See you there',
      time: 'Thursday',
      image: 'assets/images/hasan.jpeg',
      accent: Color(0xffe67e22)),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('WhatsApp'),
          backgroundColor: const Color.fromARGB(255, 48, 210, 191),
          foregroundColor: Colors.white,
          bottom: const TabBar(tabs: [
            Tab(icon: Icon(Icons.camera_alt_outlined)),
            Tab(text: 'Chats'),
            Tab(text: 'Status'),
            Tab(text: 'Calls'),
          ]),
          actions: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
            PopupMenuButton(
                onSelected: (value) {
                  if (value == 6) {
                    _logout();
                  }
                },
                icon: const Icon(Icons.more_vert_outlined),
                itemBuilder: (
                  context,
                ) =>
                    const [
                      PopupMenuItem(value: 1, child: Text('New Group')),
                      PopupMenuItem(value: 2, child: Text('New broadcast')),
                      PopupMenuItem(value: 3, child: Text('Linked devices')),
                      PopupMenuItem(value: 4, child: Text('Starred messages')),
                      PopupMenuItem(value: 5, child: Text('Settings')),
                      PopupMenuItem(value: 6, child: Text('Logout')),
                    ])
          ],
        ),
        body: TabBarView(children: [
          const Center(
              child: Icon(Icons.camera_alt_outlined,
                  size: 48, color: Color(0xff075e54))),
          _ContactList(
              contacts: _contacts,
              onTap: (contact) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ChatScreen(userName: contact.name)));
              }),
          _ContactList(
              contacts: _contacts
                  .map((contact) => _Contact(
                        name: contact.name,
                        preview: '${contact.time} ago',
                        time: '',
                        image: contact.image,
                        accent: contact.accent,
                      ))
                  .toList()),
          _ContactList(
              contacts: _contacts
                  .map((contact) => _Contact(
                        name: contact.name,
                        preview: contact.name == 'Danish Raza'
                            ? 'You missed a call'
                            : 'Tap to call back',
                        time: contact.time,
                        image: contact.image,
                        accent: contact.accent,
                      ))
                  .toList(),
              showCallIcon: true),
        ]),
      ),
    );
  }
}

class _ContactList extends StatelessWidget {
  final List<_Contact> contacts;
  final ValueChanged<_Contact>? onTap;
  final bool showCallIcon;

  const _ContactList(
      {required this.contacts, this.onTap, this.showCallIcon = false});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: contacts.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 88),
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          onTap: onTap == null ? null : () => onTap!(contact),
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: contact.accent,
            backgroundImage: AssetImage(contact.image),
          ),
          title: Text(contact.name,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(contact.preview),
          trailing: showCallIcon
              ? Icon(Icons.call, color: contact.accent)
              : Text(contact.time,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        );
      },
    );
  }
}
