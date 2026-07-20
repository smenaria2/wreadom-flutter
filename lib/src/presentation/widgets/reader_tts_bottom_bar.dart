import 'dart:async';
import 'package:flutter/material.dart';
import 'package:librebook_flutter/src/utils/app_haptics.dart';
import 'glass_surface.dart';

class ReaderTtsBottomBar extends StatefulWidget {
  const ReaderTtsBottomBar({
    super.key,
    required this.visible,
    required this.isPreparing,
    required this.isPlaying,
    required this.isPaused,
    required this.currentBlockIndex,
    required this.totalBlocks,
    required this.currentSpeed,
    required this.selectedVoice,
    required this.availableVoices,
    required this.onPlayPause,
    required this.onStop,
    required this.onPreviousBlock,
    required this.onNextBlock,
    required this.onSpeedChanged,
    required this.onVoiceChanged,
    required this.chromeTheme,
    required this.bookLanguage,
  });

  final bool visible;
  final bool isPreparing;
  final bool isPlaying;
  final bool isPaused;
  final int currentBlockIndex;
  final int totalBlocks;
  final double currentSpeed;
  final Map<String, String>? selectedVoice;
  final List<Map<String, String>> availableVoices;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;
  final VoidCallback? onPreviousBlock;
  final VoidCallback? onNextBlock;
  final ValueChanged<double> onSpeedChanged;
  final ValueChanged<Map<String, String>?> onVoiceChanged;
  final ThemeData chromeTheme;
  final String bookLanguage;

  @override
  State<ReaderTtsBottomBar> createState() => _ReaderTtsBottomBarState();
}

class _ReaderTtsBottomBarState extends State<ReaderTtsBottomBar> {
  static const double _barHeight = 72.0;
  static const Duration _animationDuration = Duration(milliseconds: 180);

  @override
  Widget build(BuildContext context) {
    final colorScheme = widget.chromeTheme.colorScheme;
    final textColor = colorScheme.onSurface;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    // Progress calculation
    final progress = widget.totalBlocks > 0
        ? (widget.currentBlockIndex + 1) / widget.totalBlocks
        : 0.0;

    return Theme(
      data: widget.chromeTheme,
      child: AnimatedContainer(
        duration: _animationDuration,
        curve: Curves.easeOut,
        height: widget.visible ? (_barHeight + bottomPadding) : 0,
        child: ClipRect(
          child: GlassSurface(
            strong: true,
            borderRadius: BorderRadius.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: colorScheme.onSurface.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  minHeight: 2,
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 12,
                      right: 12,
                      bottom: bottomPadding,
                    ),
                    child: Row(
                      children: [
                        // Speed Controller Button
                        _buildSpeedButton(context, colorScheme),
                        
                        const Spacer(),
                        
                        // Media Controls: Prev, Play/Pause, Next
                        IconButton(
                          icon: const Icon(Icons.skip_previous_rounded, size: 28),
                          onPressed: widget.onPreviousBlock != null
                              ? () {
                                  unawaited(AppHaptics.selection());
                                  widget.onPreviousBlock!();
                                }
                              : null,
                          color: textColor.withValues(alpha: widget.onPreviousBlock != null ? 0.9 : 0.3),
                          tooltip: 'Previous block',
                        ),
                        const SizedBox(width: 8),
                        _buildPlayPauseButton(colorScheme),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded, size: 28),
                          onPressed: widget.onNextBlock != null
                              ? () {
                                  unawaited(AppHaptics.selection());
                                  widget.onNextBlock!();
                                }
                              : null,
                          color: textColor.withValues(alpha: widget.onNextBlock != null ? 0.9 : 0.3),
                          tooltip: 'Next block',
                        ),
                        
                        const Spacer(),
                        
                        // Voice Selection Button
                        IconButton(
                          icon: Icon(
                            widget.selectedVoice != null
                                ? Icons.record_voice_over_rounded
                                : Icons.voice_over_off_rounded,
                            size: 24,
                          ),
                          onPressed: () {
                            unawaited(AppHaptics.selection());
                            _showVoiceSelectorBottomSheet(context);
                          },
                          color: textColor.withValues(alpha: 0.8),
                          tooltip: 'Select voice',
                        ),
                        
                        // Stop Button
                        IconButton(
                          icon: const Icon(Icons.stop_circle_rounded, size: 24),
                          onPressed: () {
                            unawaited(AppHaptics.selection());
                            widget.onStop();
                          },
                          color: Colors.redAccent.withValues(alpha: 0.8),
                          tooltip: 'Stop TTS',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayPauseButton(ColorScheme colorScheme) {
    if (widget.isPreparing) {
      return Container(
        width: 44,
        height: 44,
        padding: const EdgeInsets.all(10),
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: colorScheme.primary,
        ),
      );
    }

    final isPlaying = widget.isPlaying;
    return IconButton(
      icon: Icon(
        isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
        size: 44,
      ),
      onPressed: () {
        unawaited(AppHaptics.selection());
        widget.onPlayPause();
      },
      color: colorScheme.primary,
      padding: EdgeInsets.zero,
      tooltip: isPlaying ? 'Pause' : 'Resume',
    );
  }

  Widget _buildSpeedButton(BuildContext context, ColorScheme colorScheme) {
    final speeds = [0.25, 0.45, 0.6, 0.8, 1.0, 1.25, 1.5, 2.0];
    // Map speech rates to readable speed multiples (0.45 is the default standard speed)
    final double displaySpeed;
    if ((widget.currentSpeed - 0.45).abs() < 0.02) {
      displaySpeed = 1.0;
    } else {
      displaySpeed = double.parse((widget.currentSpeed / 0.45).toStringAsFixed(1));
    }

    return PopupMenuButton<double>(
      initialValue: widget.currentSpeed,
      tooltip: 'Playback speed',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.onSurface.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.speed_rounded, size: 14, color: colorScheme.onSurface.withValues(alpha: 0.8)),
            const SizedBox(width: 4),
            Text(
              '${displaySpeed}x',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
      onSelected: (speed) {
        unawaited(AppHaptics.selection());
        widget.onSpeedChanged(speed);
      },
      itemBuilder: (context) {
        return speeds.map((speed) {
          final double labelSpeed;
          if ((speed - 0.45).abs() < 0.02) {
            labelSpeed = 1.0;
          } else {
            labelSpeed = double.parse((speed / 0.45).toStringAsFixed(1));
          }
          return PopupMenuItem<double>(
            value: speed,
            child: Row(
              children: [
                if ((speed - widget.currentSpeed).abs() < 0.01)
                  Icon(Icons.check_rounded, size: 16, color: colorScheme.primary)
                else
                  const SizedBox(width: 16),
                const SizedBox(width: 8),
                Text(
                  '${labelSpeed}x ${speed == 0.45 ? "(Default)" : ""}',
                  style: TextStyle(
                    fontWeight: (speed - widget.currentSpeed).abs() < 0.01
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  void _showVoiceSelectorBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _VoiceSelectorSheet(
          availableVoices: widget.availableVoices,
          selectedVoice: widget.selectedVoice,
          bookLanguage: widget.bookLanguage,
          chromeTheme: widget.chromeTheme,
          onVoiceChanged: widget.onVoiceChanged,
        );
      },
    );
  }
}

class _VoiceSelectorSheet extends StatefulWidget {
  const _VoiceSelectorSheet({
    required this.availableVoices,
    required this.selectedVoice,
    required this.bookLanguage,
    required this.chromeTheme,
    required this.onVoiceChanged,
  });

  final List<Map<String, String>> availableVoices;
  final Map<String, String>? selectedVoice;
  final String bookLanguage;
  final ThemeData chromeTheme;
  final ValueChanged<Map<String, String>?> onVoiceChanged;

  @override
  State<_VoiceSelectorSheet> createState() => _VoiceSelectorSheetState();
}

class _VoiceSelectorSheetState extends State<_VoiceSelectorSheet> {
  bool _showAllLanguages = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = widget.chromeTheme.colorScheme;
    final textColor = colorScheme.onSurface;

    // Determine target locale prefix
    final cleanLang = widget.bookLanguage.toLowerCase().trim();
    final String targetLocalePrefix;
    if (cleanLang.startsWith('en') || cleanLang.startsWith('eng')) {
      targetLocalePrefix = 'en';
    } else if (cleanLang.startsWith('hi') || cleanLang.startsWith('hin')) {
      targetLocalePrefix = 'hi';
    } else if (cleanLang.length >= 2) {
      targetLocalePrefix = cleanLang.substring(0, 2);
    } else {
      targetLocalePrefix = cleanLang;
    }

    // Filtered voices list
    final filteredVoices = widget.availableVoices.where((voice) {
      if (_showAllLanguages) return true;
      final locale = voice['locale']?.toLowerCase() ?? '';
      return locale.startsWith(targetLocalePrefix);
    }).toList();

    return GlassSurface(
      strong: true,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pull Bar indicator
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reading Voice',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Show All',
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor.withValues(alpha: 0.7),
                          ),
                        ),
                        Switch.adaptive(
                          value: _showAllLanguages,
                          onChanged: (val) {
                            unawaited(AppHaptics.selection());
                            setState(() {
                              _showAllLanguages = val;
                            });
                          },
                          activeThumbColor: colorScheme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              
              // Voice list
              Flexible(
                child: filteredVoices.isEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        alignment: Alignment.center,
                        child: Text(
                          widget.availableVoices.isEmpty
                              ? 'No system voices available'
                              : 'No voices found for "${widget.bookLanguage}"',
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.6),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredVoices.length + 1, // +1 for "System Default" option
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            final isSelected = widget.selectedVoice == null;
                            return ListTile(
                              leading: Icon(
                                Icons.settings_suggest_rounded,
                                color: isSelected ? colorScheme.primary : textColor.withValues(alpha: 0.6),
                              ),
                              title: Text(
                                'System Default',
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? colorScheme.primary : textColor,
                                ),
                              ),
                              subtitle: const Text('Let the OS choose the best voice'),
                              trailing: isSelected
                                  ? Icon(Icons.check_rounded, color: colorScheme.primary)
                                  : null,
                              onTap: () {
                                unawaited(AppHaptics.selection());
                                widget.onVoiceChanged(null);
                                Navigator.pop(context);
                              },
                            );
                          }

                          final voice = filteredVoices[index - 1];
                          final voiceName = voice['name'] ?? '';
                          final voiceLocale = voice['locale'] ?? '';
                          final isSelected = widget.selectedVoice != null &&
                              widget.selectedVoice!['name'] == voiceName;

                          // Beautify voice name for display
                          // Google en-US voices look like "en-us-x-sfg#male_1-local"
                          var displayName = voiceName
                              .replaceAll(RegExp(r'-local$'), '')
                              .replaceAll(RegExp(r'[^a-zA-Z0-9#_]'), ' ')
                              .toUpperCase();
                          if (displayName.startsWith('GOOGLE ')) {
                            displayName = displayName.substring(7);
                          }

                          return ListTile(
                            leading: Icon(
                              Icons.record_voice_over_rounded,
                              color: isSelected ? colorScheme.primary : textColor.withValues(alpha: 0.6),
                            ),
                            title: Text(
                              displayName,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? colorScheme.primary : textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text('Locale: $voiceLocale'),
                            trailing: isSelected
                                ? Icon(Icons.check_rounded, color: colorScheme.primary)
                                : null,
                            onTap: () {
                              unawaited(AppHaptics.selection());
                              widget.onVoiceChanged(voice);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
