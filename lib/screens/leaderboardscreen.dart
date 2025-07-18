import 'package:flutter/material.dart';
import 'package:simple_game_1/services/local_player_service.dart';
import 'package:simple_game_1/models/player_leaderboard_entry.dart';
import 'package:simple_game_1/supporting/developer_apps_page.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  PlayerLeaderboardEntry? _playerRecord;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    final record = await LocalPlayerService.loadMyRecord();
    setState(() {
      _playerRecord = record;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildDeveloperAppsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.purpleAccent, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'MORE APPS BY DEVELOPER',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Akira',
                    fontSize: 14,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: const Text(
                  'ADS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: DeveloperApps(mode: DeveloperAppsMode.horizontal),
        ),
      ],
    );
  }

  Widget _buildScoreCard(String title, String value) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF00FFFF).withOpacity(0.3),
            Color(0xFFFF00FF).withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purpleAccent, width: 1),
      ),
      child: ListTile(
        leading: const Icon(Icons.bolt, color: Colors.yellowAccent, size: 30),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Akira',
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        trailing: Text(
          value,
          style: const TextStyle(
            fontFamily: 'Akira',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildYourScoresTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_playerRecord == null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purpleAccent, width: 1),
          ),
          child: const Text(
            "NO RECORD FOUND",
            style: TextStyle(
              fontFamily: 'Akira',
              fontSize: 18,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildScoreCard(
                  "Classic High Score",
                  _playerRecord!.classicHighScore.toString(),
                ),
                _buildScoreCard(
                  "Endless High Score",
                  _playerRecord!.endlessHighScore.toString(),
                ),
              ],
            ),
          ),
        ),
        // Fixed section at the bottom
        _buildDeveloperAppsSection(),
      ],
    );
  }

  Widget _buildGlobalTab() {
    return Column(
      children: [
        const Expanded(
          child: Center(
            child: Text(
              "GLOBAL LEADERBOARD COMING SOON...",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Akira',
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
        _buildDeveloperAppsSection(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            // "assets/images/leaderboard_screen.png",
            "assets/images/modeselectBG.png",
            fit: BoxFit.cover,
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,

          appBar: AppBar(
            backgroundColor: Colors.black.withOpacity(0.6),
            elevation: 0,
            iconTheme: const IconThemeData(
              color: Colors.white, // makes the back arrow white
            ),
            title: const Text(
              "LEADERBOARD",
              style: TextStyle(
                fontFamily: 'Akira',
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            // bottom: TabBar(
            //   controller: _tabController,
            //   indicatorColor: Colors.amber,
            //   labelColor: Colors.amber,
            //   unselectedLabelColor: Colors.white70,
            //   labelStyle: const TextStyle(
            //     fontFamily: 'Akira',
            //     fontSize: 14,
            //     letterSpacing: 1.1,
            //   ),
            //   tabs: const [
            //     Tab(text: "YOUR SCORES"),
            //     Tab(text: "GLOBAL"),
            //   ],
            // ),
          ),
          body: Column(
            children: [
              Container(
                color: Colors.black.withOpacity(0.6),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.amber,
                  labelColor: Colors.amber,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: const TextStyle(
                    fontFamily: 'Akira',
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                  tabs: const [
                    Tab(text: "YOUR SCORES"),
                    Tab(text: "GLOBAL"),
                  ],
                ),
              ),
              SizedBox(height: 12), // This adds spacing below the TabBar
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildYourScoresTab(), _buildGlobalTab()],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
