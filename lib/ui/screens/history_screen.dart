import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/history_provider.dart';
import '../widgets/article_card.dart';
import '../widgets/empty_state_widget.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final historyProvider = Provider.of<HistoryProvider>(context);
    final history = historyProvider.history;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading History'),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear History',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear Reading History?'),
                    content: const Text('This will remove all records of articles you have read.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          historyProvider.clearHistory();
                          Navigator.pop(ctx);
                        },
                        style: TextButton.styleFrom(foregroundColor: AppColors.error),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: history.isEmpty
          ? const EmptyStateWidget(
              title: 'No Reading History',
              message: 'Articles you read will automatically appear here so you can easily revisit them.',
              icon: Icons.history_rounded,
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 2),
                      child: Text(
                        'Read ${DateFormat('MMM d • h:mm a').format(item.readAt)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    ArticleCard(article: item.article, isHorizontal: true),
                  ],
                );
              },
            ),
    );
  }
}

