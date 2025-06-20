// lib/screens/groups/group_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/group_model.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';

// This is the full, multi-tabbed detail screen from your images,
// adapted to use the GroupModel and live data for the Members tab.
class GroupDetailScreen extends StatefulWidget {
  final GroupModel group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  GroupDetailScreenState createState() => GroupDetailScreenState();
}

class GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Future<List<UserModel?>>? _membersFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchMembers();
  }

  void _fetchMembers() {
    // Fetch member details when the screen initializes
    if (mounted) {
       setState(() {
        _membersFuture = Provider.of<UserProvider>(context, listen: false)
            .getUsersByIds(widget.group.memberIds);
       });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: () => _showInviteDialog(),
                child: const ListTile(
                  leading: Icon(Icons.person_add_outlined),
                  title: Text('Invite Members'),
                ),
              ),
              PopupMenuItem(
                onTap: () => _showGroupSettings(),
                child: const ListTile(
                  leading: Icon(Icons.settings_outlined),
                  title: Text('Group Settings'),
                ),
              ),
              PopupMenuItem(
                onTap: () => _shareGroup(),
                child: const ListTile(
                  leading: Icon(Icons.share_outlined),
                  title: Text('Share Group'),
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Restaurants'),
            Tab(text: 'Members'),
            Tab(text: 'Ratings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildRestaurantsTab(),
          _buildMembersTab(),
          _buildRatingsTab(),
        ],
      ),
    );
  }

  // --- DETAIL SCREEN TAB BUILDERS ---

  Widget _buildOverviewTab() {
    final color = _getColorForGroup();
    final icon = _getIconForGroup();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: color.withAlpha(40),
                        child: Icon(
                          icon,
                          color: color,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.group.name,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            Text(
                              '${widget.group.memberIds.length} members',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.group.description ?? 'No description provided.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoSection('Common Preferences', Icons.favorite, widget.group.groupPreferences, Colors.green),
          const SizedBox(height: 16),
          if (widget.group.groupAllergies.isNotEmpty)
            _buildInfoSection('Common Allergies', Icons.warning, widget.group.groupAllergies, Colors.red),
          const SizedBox(height: 16),
          // AI Suggestions Card
          Card(
            color: Colors.blue.withAlpha(25),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'AI Recommendations',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Based on your group\'s preferences, we suggest trying Mediterranean or Thai cuisine for your next outing.',
                    style: TextStyle(height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Finding restaurants...')),
                      );
                    },
                    child: const Text('Find Restaurants'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantsTab() {
    // Placeholder - This would fetch and display restaurants rated by the group
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
          Text('Top Group Restaurants', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          const ListTile(
            leading: CircleAvatar(backgroundColor: Colors.amber, child: Text('1')),
            title: Text("Mario's Kitchen"),
            subtitle: Text('Group Rating: 4.8'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.star, color: Colors.amber, size: 16), Text(' 4.8')]),
          ),
           const ListTile(
            leading: CircleAvatar(backgroundColor: Colors.amber, child: Text('2')),
            title: Text("Burger Hub"),
            subtitle: Text('Group Rating: 4.5'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.star, color: Colors.amber, size: 16), Text(' 4.5')]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showRateRestaurantDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Rate a Restaurant'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
          ),
      ],
    );
  }

  Widget _buildMembersTab() {
    return FutureBuilder<List<UserModel?>>(
      future: _membersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('Error loading members.'));
        }
        final members = snapshot.data!.where((m) => m != null).cast<UserModel>().toList();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () => _showInviteDialog(),
                icon: const Icon(Icons.person_add),
                label: const Text('Invite Members'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  final bool isAdmin = member.id == widget.group.adminId;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: member.avatarUrl != null && member.avatarUrl!.isNotEmpty
                          ? NetworkImage(member.avatarUrl!)
                          : null,
                      child: (member.avatarUrl == null || member.avatarUrl!.isEmpty)
                          ? Text(member.name.isNotEmpty ? member.name[0].toUpperCase() : '?')
                          : null,
                    ),
                    title: Text(member.name),
                    subtitle: Text(isAdmin ? 'Admin' : 'Member'),
                    trailing: isAdmin ? Icon(Icons.admin_panel_settings, color: Theme.of(context).primaryColor) : null,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRatingsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Group Rating System',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Share rating links with your group members to collect feedback on restaurants you\'ve visited together.',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _generateRatingLink(),
            icon: const Icon(Icons.link),
            label: const Text('Generate Rating Link'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, IconData icon, List<dynamic> items, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items
                  .map<Widget>((item) => Chip(
                        label: Text(item),
                        backgroundColor: color.withAlpha(30),
                        side: BorderSide(color: color.withAlpha(80)),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  // --- DETAIL SCREEN DIALOGS & ACTIONS ---
  
  void _showInviteDialog() {
    // We pop the PopupMenuButton's route first
    Navigator.pop(context); 
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite Members'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              decoration: InputDecoration(
                labelText: 'Email or Phone',
                hintText: 'Enter email or phone number',
              ),
            ),
            const SizedBox(height: 16),
            const Text('Or share invite link:', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const SelectableText('https://app.foodie/groups/invite/abc123', style: TextStyle(fontFamily: 'monospace')),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invite sent!')));
            },
            child: const Text('Send Invite'),
          ),
        ],
      ),
    );
  }

  void _showGroupSettings() {
     Navigator.pop(context); // Close the PopupMenu
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Group settings coming soon!')));
  }

  void _shareGroup() {
    Navigator.pop(context); // Close the PopupMenu
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share functionality coming soon!')));
  }

  void _showRateRestaurantDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate a Restaurant'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Restaurant Name',
                hintText: 'Which restaurant did you visit?',
              ),
            ),
            SizedBox(height: 16),
            Text('This will generate a rating link to share with your group members.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rating link generated!')));
            },
            child: const Text('Generate Link'),
          ),
        ],
      ),
    );
  }

  void _generateRatingLink() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Rating link: https://app.foodie/rate/group123'),
        action: SnackBarAction(label: 'Copy', onPressed: () {}),
      ),
    );
  }

  // --- HELPERS ---
  Color _getColorForGroup() {
    final colors = [Colors.blue, Colors.orange, Colors.green, Colors.purple, Colors.red, Colors.teal];
    return colors[widget.group.name.hashCode % colors.length];
  }

  IconData _getIconForGroup() {
    final icons = [Icons.family_restroom, Icons.work, Icons.school, Icons.sports_kabaddi, Icons.local_bar, Icons.celebration];
    return icons[widget.group.name.hashCode % icons.length];
  }
}
