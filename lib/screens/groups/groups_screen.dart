// lib/screens/groups/groups_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../models/group_model.dart';
import '../../models/user_model.dart';
import '../../models/restaurant_model.dart';
import '../../models/group_rating_model.dart';
import 'create_group_screen.dart';
import '../restaurant/restaurant_detail_screen.dart';

// Main Screen that shows the list of groups
class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  GroupsScreenState createState() => GroupsScreenState();
}

class GroupsScreenState extends State<GroupsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGroups();
    });
  }

  Future<void> _loadGroups() async {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    String? currentUserId = authProvider.userModel?.id;
    if (currentUserId != null && currentUserId.isNotEmpty) {
      await groupProvider.loadUserGroups(currentUserId);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGroups,
            tooltip: 'Refresh Groups',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.group_outlined), text: 'My Groups'),
            Tab(icon: Icon(Icons.explore_outlined), text: 'Discover'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyGroupsTab(context),
          _buildDiscoverTab(context),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
          ).then((_) {
            _loadGroups();
          });
        },
        tooltip: 'Create New Group',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMyGroupsTab(BuildContext context) {
    return Consumer<GroupProvider>(
      builder: (context, groupProvider, child) {
        if (groupProvider.isLoading && groupProvider.userGroups.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (groupProvider.errorMessage != null &&
            groupProvider.userGroups.isEmpty) {
          return Center(
              child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 60, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        Text("Error Loading Groups",
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(groupProvider.errorMessage!,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                            onPressed: _loadGroups)
                      ])));
        }
        final filteredGroups = groupProvider.userGroups.where((group) {
          return group.name.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();
        if (groupProvider.userGroups.isEmpty) {
          return Center(
              child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.group_add_outlined,
                            size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 20),
                        Text('No Groups Yet',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        Text(
                            'Create a group with your friends, family, or colleagues to find the perfect place to eat together!',
                            style: TextStyle(color: Colors.grey[500]),
                            textAlign: TextAlign.center)
                      ])));
        }
        return Column(children: [
          Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                      hintText: 'Search your groups...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest))),
          if (filteredGroups.isEmpty && _searchQuery.isNotEmpty)
            const Padding(
                padding: EdgeInsets.only(top: 20.0),
                child: Center(child: Text('No groups found for your search.')))
          else
            Expanded(
                child: RefreshIndicator(
                    onRefresh: _loadGroups,
                    child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredGroups.length,
                        itemBuilder: (context, index) {
                          final group = filteredGroups[index];
                          return GroupCard(
                              group: group,
                              onTap: () => _navigateToGroupDetail(group));
                        })))
        ]);
      },
    );
  }

  Widget _buildDiscoverTab(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.explore_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Discover for Your Groups',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
                'Based on your groups\' preferences and dining history, find new restaurants perfect for your next outing.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('AI recommendations coming soon!')));
                },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Get AI Suggestions'))
          ],
        ),
      ),
    );
  }

  void _navigateToGroupDetail(GroupModel group) {
    Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => GroupDetailScreen(group: group)));
  }
}

// --- WIDGETS USED IN THIS SCREEN ---

class GroupCard extends StatelessWidget {
  final GroupModel group;
  final VoidCallback onTap;

  const GroupCard({super.key, required this.group, required this.onTap});

  Color _getColorForGroup() {
    final colors = [
      Colors.blue, Colors.orange, Colors.green, Colors.purple,
      Colors.red, Colors.teal
    ];
    return colors[group.name.hashCode % colors.length];
  }

  IconData _getIconForGroup() {
    final icons = [
      Icons.family_restroom, Icons.work, Icons.school,
      Icons.sports_kabaddi, Icons.local_bar, Icons.celebration
    ];
    return icons[group.name.hashCode % icons.length];
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorForGroup();
    final icon = _getIconForGroup();
    return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        CircleAvatar(
                            backgroundColor: color.withAlpha(40),
                            child: Icon(icon, color: color)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(group.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              Text('${group.memberIds.length} members',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.grey[600]))
                            ])),
                        const Icon(Icons.chevron_right, color: Colors.grey)
                      ]),
                      if (group.description != null &&
                          group.description!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(group.description!,
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis)
                      ],
                      if (group.groupPreferences.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: group.groupPreferences
                                .map<Widget>((pref) => Chip(
                                    label: Text(pref),
                                    backgroundColor: Colors.green.withAlpha(30),
                                    labelStyle: const TextStyle(fontSize: 11),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 0),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap))
                                .toList())
                      ]
                    ]))));
  }
}

// --- GROUP DETAIL SCREEN (Included in same file as per your original code) ---

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
  Future<List<RestaurantModel>>? _groupTopRestaurantsFuture;
  Future<List<GroupRatingModel>>? _groupRatingsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchMembers();
    _fetchGroupTopRestaurants();
    _fetchGroupRatings();
  }

  void _fetchMembers() {
    if (mounted) {
      setState(() {
        _membersFuture = Provider.of<UserProvider>(context, listen: false)
            .getUsersByIds(widget.group.memberIds);
      });
    }
  }

  void _fetchGroupTopRestaurants() {
    if (mounted && widget.group.topRestaurantIds.isNotEmpty) {
      setState(() {
        _groupTopRestaurantsFuture =
            Provider.of<RestaurantProvider>(context, listen: false)
                .getRestaurantsByIds(widget.group.topRestaurantIds);
      });
    } else {
      setState(() {
        _groupTopRestaurantsFuture = Future.value([]);
      });
    }
  }

  void _fetchGroupRatings() {
    if (mounted) {
      setState(() {
        _groupRatingsFuture =
            Provider.of<GroupProvider>(context, listen: false)
                .fetchGroupRatings(widget.group.id);
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
                          onTap: () =>
                              Future.delayed(const Duration(seconds: 0),
                                  () => _showInviteDialog()),
                          child: const ListTile(
                              leading: Icon(Icons.person_add),
                              title: Text('Invite Members'))),
                      PopupMenuItem(
                          onTap: _showGroupSettings,
                          child: const ListTile(
                              leading: Icon(Icons.settings),
                              title: Text('Group Settings'))),
                      PopupMenuItem(
                          onTap: _shareGroup,
                          child: const ListTile(
                              leading: Icon(Icons.share),
                              title: Text('Share Group')))
                    ])
          ],
          bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Restaurants'),
                Tab(text: 'Members'),
                Tab(text: 'Ratings')
              ]),
        ),
        body: TabBarView(controller: _tabController, children: [
          _buildOverviewTab(),
          _buildRestaurantsTab(),
          _buildMembersTab(),
          _buildRatingsTab()
        ]));
  }

  // --- DETAIL SCREEN TAB BUILDERS ---

  Widget _buildOverviewTab() {
    final color = GroupCard(group: widget.group, onTap: () {})
        ._getColorForGroup();
    final icon =
        GroupCard(group: widget.group, onTap: () {})._getIconForGroup();
    return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          CircleAvatar(
                              radius: 30,
                              backgroundColor: color.withAlpha(40),
                              child: Icon(icon, color: color, size: 30)),
                          const SizedBox(width: 16),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(widget.group.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall),
                                Text(
                                    '${widget.group.memberIds.length} members',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.grey[600]))
                              ]))
                        ]),
                        const SizedBox(height: 16),
                        Text(widget.group.description ?? 'No description provided.',
                            style: Theme.of(context).textTheme.bodyLarge)
                      ]))),
          const SizedBox(height: 16),
          _buildInfoSection('Common Preferences', Icons.favorite,
              widget.group.groupPreferences, Colors.green),
          const SizedBox(height: 16),
          if (widget.group.groupAllergies.isNotEmpty)
            _buildInfoSection('Common Allergies', Icons.warning,
                widget.group.groupAllergies, Colors.red),
          const SizedBox(height: 16),
          Card(
              color: Colors.blue.withAlpha(25),
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    Row(children: [
                      const Icon(Icons.auto_awesome, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text('AI Recommendations',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue))
                    ]),
                    const SizedBox(height: 8),
                    const Text(
                        'Based on your group\'s preferences, we suggest trying Mediterranean or Thai cuisine for your next outing.',
                        style: TextStyle(height: 1.4)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Finding restaurants...')));
                        },
                        child: const Text('Find Restaurants'))
                  ])))
        ]));
  }

  Widget _buildRestaurantsTab() {
    return FutureBuilder<List<RestaurantModel>>(
        future: _groupTopRestaurantsFuture,
        builder: (context, snapshot) {
          if (widget.group.topRestaurantIds.isEmpty) {
            return const Center(
                child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                        'This group hasn\'t selected any top restaurants yet!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey))));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('Could not load restaurant details.'));
          }
          final restaurants = snapshot.data!;
          return ListView(padding: const EdgeInsets.all(16.0), children: [
            Text('Group\'s Top Restaurants',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...restaurants.map((restaurant) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                    leading: CircleAvatar(
                        backgroundImage: restaurant.images.isNotEmpty
                            ? NetworkImage(restaurant.images.first)
                            : null,
                        child: restaurant.images.isEmpty
                            ? const Icon(Icons.restaurant_menu)
                            : null),
                    title: Text(restaurant.name),
                    subtitle: Text(restaurant.cuisineTypes.join(', ')),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.star,
                          color: Colors.amber, size: 16),
                      Text(
                          ' ${restaurant.ratingGoogle.toStringAsFixed(1)}')
                    ]),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  RestaurantDetailScreen(
                                      restaurant: restaurant)));
                    })))
          ]);
        });
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
          final members = snapshot.data!
              .where((m) => m != null)
              .cast<UserModel>()
              .toList();
          return Column(children: [
            Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                    onPressed: () => _showInviteDialog(),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Invite Members'),
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48)))),
            Expanded(
                child: ListView.builder(
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      final bool isAdmin = member.id == widget.group.adminId;
                      return ListTile(
                          leading: CircleAvatar(
                              backgroundImage: member.avatarUrl != null &&
                                      member.avatarUrl!.isNotEmpty
                                  ? NetworkImage(member.avatarUrl!)
                                  : null,
                              child: (member.avatarUrl == null ||
                                      member.avatarUrl!.isEmpty)
                                  ? Text(member.name.isNotEmpty
                                      ? member.name[0].toUpperCase()
                                      : '?')
                                  : null),
                          title: Text(member.name),
                          subtitle: Text(isAdmin ? 'Admin' : 'Member'),
                          trailing: isAdmin
                              ? Icon(Icons.admin_panel_settings,
                                  color: Theme.of(context).primaryColor)
                              : null);
                    }))
          ]);
        });
  }

  Widget _buildRatingsTab() {
    return FutureBuilder<List<GroupRatingModel>>(
        future: _groupRatingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Error loading ratings: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.rate_review_outlined,
                              size: 80, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text('No Ratings Yet',
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 8),
                          const Text(
                              'Rate a restaurant to start your group\'s leaderboard!',
                              textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                              onPressed: () => _showRateRestaurantDialog(),
                              icon: const Icon(Icons.add),
                              label: const Text('Rate a Restaurant'))
                        ])));
          }
          final ratings = snapshot.data!;
          return RefreshIndicator(
              onRefresh: () async {
                _fetchGroupRatings();
              },
              child: ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: ratings.length,
                  itemBuilder: (context, index) {
                    final rating = ratings[index];
                    final rank = index + 1;
                    return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        child: ListTile(
                            leading: CircleAvatar(
                                backgroundColor: _getColorForRank(rank),
                                foregroundColor: Colors.white,
                                child: Text('$rank',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold))),
                            title: Text(rating.restaurantName),
                            subtitle: Text(
                                '${rating.memberRatings.length} members rated'),
                            trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded,
                                      color: Colors.amber, size: 20),
                                  const SizedBox(width: 4),
                                  Text(
                                      rating.averageRating.toStringAsFixed(1),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold))
                                ]),
                            onTap: () {
                              // TODO: Navigate to restaurant detail, maybe with group rating context
                            }));
                  }));
        });
  }

  Widget _buildInfoSection(
      String title, IconData icon, List<dynamic> items, Color color) {
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold))
              ]),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const Text('None specified yet.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
              else
                Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: items
                        .map<Widget>((item) => Chip(
                            label: Text(item),
                            backgroundColor: color.withAlpha(30),
                            side: BorderSide(color: color.withAlpha(80))))
                        .toList())
            ])));
  }

  void _showInviteDialog() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
            title: const Text('Invite Members'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              const TextField(
                  decoration: InputDecoration(
                      labelText: 'Email or Phone',
                      hintText: 'Enter email or phone number')),
              const SizedBox(height: 16),
              const Text('Or share invite link:',
                  style: TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8)),
                  child: const SelectableText(
                      'https://app.foodie/groups/invite/abc123',
                      style: TextStyle(fontFamily: 'monospace')))
            ]),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
              ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invite sent!')));
                  },
                  child: const Text('Send Invite'))
            ]));
  }

  void _showGroupSettings() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Group settings coming soon!')));
  }

  void _shareGroup() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Share functionality coming soon!')));
  }

  void _showRateRestaurantDialog() {
    showDialog(
      context: context,
      builder: (context) => RateRestaurantDialog(
        groupId: widget.group.id,
        onRatingSubmitted: () {
          // Refresh the ratings list after submission
          _fetchGroupRatings();
        },
      ),
    );
  }

  Color _getColorForRank(int rank) {
    if (rank == 1) return Colors.amber.shade700;
    if (rank == 2) return Colors.grey.shade500;
    if (rank == 3) return Colors.brown.shade400;
    return Theme.of(context).primaryColor;
  }
}

// --- NEW WIDGET FOR THE RATING DIALOG ---
class RateRestaurantDialog extends StatefulWidget {
  final String groupId;
  final VoidCallback onRatingSubmitted;

  const RateRestaurantDialog({
    super.key,
    required this.groupId,
    required this.onRatingSubmitted,
  });

  @override
  State<RateRestaurantDialog> createState() => _RateRestaurantDialogState();
}

class _RateRestaurantDialogState extends State<RateRestaurantDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<RestaurantModel> _searchResults = [];
  bool _isSearching = false;
  RestaurantModel? _selectedRestaurant;
  double _currentRating = 3.0;
  bool _isSubmitting = false;
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.length < 2) {
        if (mounted) setState(() => _searchResults = []);
        return;
      }
      if (mounted) setState(() => _isSearching = true);
      final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
      await restaurantProvider.searchRestaurants(query);
      if (mounted) {
        setState(() {
          _searchResults = restaurantProvider.restaurants;
          _isSearching = false;
        });
      }
    });
  }

  Future<void> _submitRating() async {
    if (_selectedRestaurant == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a restaurant.')));
      return;
    }
    if (!mounted) return;
    
    setState(() => _isSubmitting = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final userId = authProvider.userModel?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not identify user.')));
      setState(() => _isSubmitting = false);
      return;
    }

    final success = await groupProvider.rateRestaurantInGroup(
      groupId: widget.groupId,
      userId: userId,
      restaurant: _selectedRestaurant!,
      rating: _currentRating,
    );

    if (mounted) {
      if (success) {
        widget.onRatingSubmitted(); 
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rating submitted!'), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(groupProvider.errorMessage ?? 'Failed to submit rating.'), backgroundColor: Colors.red));
      }
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rate a Restaurant'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: _selectedRestaurant == null
              ? _buildSearchStep()
              : _buildRatingStep(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: (_selectedRestaurant == null || _isSubmitting) ? null : _submitRating,
          child: _isSubmitting ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Submit Rating'),
        ),
      ],
    );
  }

  Widget _buildSearchStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Search for a restaurant...'),
        ),
        const SizedBox(height: 16),
        if (_isSearching)
          const Center(child: CircularProgressIndicator())
        else if (_searchResults.isNotEmpty)
          SizedBox(
            height: 200, 
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final restaurant = _searchResults[index];
                return ListTile(
                  title: Text(restaurant.name),
                  onTap: () {
                    setState(() {
                      _selectedRestaurant = restaurant;
                    });
                  },
                );
              },
            ),
          )
        else if (_searchController.text.length >= 2)
          const Text('No results found.'),
      ],
    );
  }

  Widget _buildRatingStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          title: Text(_selectedRestaurant!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Your Rating:'),
          trailing: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _selectedRestaurant = null;
                _searchResults = [];
                _searchController.clear();
              });
            },
          ),
        ),
        const SizedBox(height: 8),
        Text('${_currentRating.toStringAsFixed(1)} / 5.0', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starNumber = index + 1;
            return IconButton(
              icon: Icon(
                _currentRating >= starNumber ? Icons.star_rounded : Icons.star_border_rounded,
                color: Colors.amber,
                size: 36,
              ),
              onPressed: () {
                setState(() {
                  _currentRating = starNumber.toDouble();
                });
              },
            );
          }),
        ),
      ],
    );
  }
}
