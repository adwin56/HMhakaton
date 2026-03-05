import 'package:flutter/material.dart';
import '../domain/get_leaders_usecase.dart';
import '../data/leaderboard_repository.dart';
import '../data/models/leader_model.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  List<Leader> _leaders = [];
  bool _isLoading = true;
  String _sortBy = 'xp'; // фильтр: xp или name

  late final GetLeadersUseCase _getLeadersUseCase;

  @override
  void initState() {
    super.initState();
    final repo = LeaderboardRepository(); // уже не нужен прямой IP
    _getLeadersUseCase = GetLeadersUseCase(repo);
    _loadLeaders();
  }

  Future<void> _loadLeaders() async {
    setState(() => _isLoading = true);
    try {
      final leaders = await _getLeadersUseCase(sortBy: _sortBy);
      setState(() {
        _leaders = leaders;
        _isLoading = false;
      });
    } catch (e) {
      _showError('Ошибка: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ошибка'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  Color _getMedalColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber.shade600; // золото
      case 1:
        return Colors.grey.shade500; // серебро
      case 2:
        return Colors.brown.shade400; // бронза
      default:
        return Colors.blueGrey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Таблица лидеров'),
        centerTitle: true,
        backgroundColor: Colors.blueGrey.shade900,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _sortBy = value);
              _loadLeaders();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'xp', child: Text('Сортировать по XP')),
              const PopupMenuItem(value: 'name', child: Text('Сортировать по имени')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: ListView.builder(
          itemCount: _leaders.length,
          itemBuilder: (context, index) {
            final leader = _leaders[index];
            final medalColor = _getMedalColor(index);

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                shadowColor: Colors.black.withOpacity(0.3),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  leading: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: leader.avatar != null
                            ? NetworkImage(leader.avatar!)
                            : null,
                        child: leader.avatar == null
                            ? Text(
                          leader.name.isNotEmpty
                              ? leader.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        )
                            : null,
                      ),
                      if (index < 3)
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: medalColor,
                          child: Icon(
                            index == 0
                                ? Icons.emoji_events
                                : Icons.star,
                            size: 12,
                            color: Colors.white,
                          ),
                        )
                    ],
                  ),
                  title: Text(
                    leader.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange.shade600, Colors.deepOrange.shade400],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'XP: ${leader.xp}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}