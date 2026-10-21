import 'package:flutter/material.dart';

import '../../domain/countdown_engine.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/labels.dart';

IconData blockIcon(BlockKind kind) => switch (kind) {
  BlockKind.weekend => Icons.weekend_outlined,
  BlockKind.longWeekend => Icons.wb_sunny_outlined,
  BlockKind.holiday => Icons.celebration_outlined,
  BlockKind.daysOff => Icons.beach_access_outlined,
};

/// Small card for "Next weekend" / "Next holiday".
class BlockCard extends StatelessWidget {
  const BlockCard({
    super.key,
    required this.title,
    required this.icon,
    required this.block,
    required this.now,
    this.loading = false,
  });

  final String title;
  final IconData icon;
  final OffBlock? block;
  final DateTime now;

  /// Shows progress instead of "none" while holidays are downloading.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final block = this.block;
    final details = block == null ? null : l10n.blockDetails(block);
    return Card(
      color: theme.colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.labelLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (block == null && loading)
              const LinearProgressIndicator()
            else if (block == null)
              Text(l10n.noneComing, style: theme.textTheme.bodyMedium)
            else ...[
              Text(
                l10n.compactDuration(block.offStart!.difference(now)),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.dateRange(block.first, block.last),
                style: theme.textTheme.bodySmall,
              ),
              Text(
                l10n.daysOffCount(block.length),
                style: theme.textTheme.bodySmall,
              ),
              if (details != null)
                Text(
                  details,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// List of the coming off-blocks.
class UpcomingList extends StatelessWidget {
  const UpcomingList({super.key, required this.blocks, required this.now});

  final List<OffBlock> blocks;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (i, block) in blocks.indexed) ...[
            if (i > 0) const Divider(height: 1, indent: 72),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: block.hasExtraOff
                    ? theme.colorScheme.tertiaryContainer
                    : theme.colorScheme.secondaryContainer,
                child: Icon(
                  blockIcon(block.kind),
                  color: block.hasExtraOff
                      ? theme.colorScheme.onTertiaryContainer
                      : theme.colorScheme.onSecondaryContainer,
                ),
              ),
              title: Text(
                l10n.blockDetails(block) ?? l10n.kindLabel(block.kind),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${l10n.dateRange(block.first, block.last)}\n'
                '${l10n.daysOffCount(block.length)}',
              ),
              isThreeLine: true,
              trailing: Text(
                l10n.inDuration(
                  l10n.compactDuration(block.offStart!.difference(now)),
                ),
                style: theme.textTheme.labelMedium,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
