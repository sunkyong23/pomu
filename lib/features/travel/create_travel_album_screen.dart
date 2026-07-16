import 'package:flutter/material.dart';

import '../../core/theme/pomu_colors.dart';
import '../../core/theme/pomu_spacing.dart';
import '../../core/widgets/buttons/pomu_primary_button.dart';
import '../../l10n/app_localizations.dart';
import '../../services/album_service.dart';
import '../../services/travel_album_builder.dart';

extension _TravelAlbumL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

class CreateTravelAlbumScreen extends StatefulWidget {
  const CreateTravelAlbumScreen({super.key});

  @override
  State<CreateTravelAlbumScreen> createState() =>
      _CreateTravelAlbumScreenState();
}

class _CreateTravelAlbumScreenState extends State<CreateTravelAlbumScreen> {
  final TravelAlbumBuilder _builder = TravelAlbumBuilder();
  final AlbumService _albumService = AlbumService();
  final TextEditingController _albumNameController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  TimeOfDay _startTime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 23, minute: 59);

  bool _isLoading = false;

  @override
  void dispose() {
    _albumNameController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final date = await _pickDate(initialDate: _startDate ?? DateTime.now());

    if (date == null) return;

    setState(() {
      _startDate = date;

      if (_endDate != null && _endDate!.isBefore(date)) {
        _endDate = date;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final date = await _pickDate(
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
    );

    if (date == null) return;

    setState(() {
      _endDate = date;

      if (_startDate != null && date.isBefore(_startDate!)) {
        _startDate = date;
      }
    });
  }

  Future<void> _pickStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime,
      helpText: context.l10n.travelPickStartTime,
      cancelText: context.l10n.cancel,
      confirmText: context.l10n.select,
    );

    if (time == null) return;

    setState(() {
      _startTime = time;
    });
  }

  Future<void> _pickEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _endTime,
      helpText: context.l10n.travelPickEndTime,
      cancelText: context.l10n.cancel,
      confirmText: context.l10n.select,
    );

    if (time == null) return;

    setState(() {
      _endTime = time;
    });
  }

  Future<DateTime?> _pickDate({required DateTime initialDate}) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: context.l10n.travelPickDate,
      cancelText: context.l10n.cancel,
      confirmText: context.l10n.select,
    );
  }

  DateTime _combineStartDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  DateTime _combineEndDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
      59,
      999,
    );
  }

  Future<void> _createAlbum() async {
    final albumName = _albumNameController.text.trim();

    if (albumName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.travelEnterAlbumName)),
      );
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.travelSelectStartAndEndDate)),
      );
      return;
    }

    final startDateTime = _combineStartDateAndTime(_startDate!, _startTime);

    final endDateTime = _combineEndDateAndTime(_endDate!, _endTime);

    if (endDateTime.isBefore(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.travelEndMustBeAfterStart)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final album = await _builder.buildTravelAlbum(
        albumName: albumName,
        startDate: startDateTime,
        endDate: endDateTime,
      );

      if (!mounted) return;

      if (album.photos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.travelNoAssetsInRange)),
        );
        return;
      }

      await _albumService.createAlbums([album]);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.travelAlbumCreated(album.photos.length)),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.travelAlbumCreateError(e.toString())),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(BuildContext context, DateTime? date) {
    if (date == null) return context.l10n.travelSelectDate;

    return MaterialLocalizations.of(context).formatMediumDate(date);
  }

  String _formatTime(BuildContext context, TimeOfDay time) {
    return MaterialLocalizations.of(context).formatTimeOfDay(time);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PomuColors.background,
      appBar: AppBar(
        backgroundColor: PomuColors.background,
        elevation: 0,
        title: Text(
          context.l10n.travelAlbumTitle,
          style: TextStyle(
            color: PomuColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(PomuSpacing.lg),
        children: [
          Text(
            context.l10n.travelAlbumHeroTitle,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: PomuColors.textPrimary,
              height: 1.15,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: PomuSpacing.xl),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.travelAlbumNameLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: PomuColors.textSecondary,
                  ),
                ),
                const SizedBox(height: PomuSpacing.sm),
                TextField(
                  controller: _albumNameController,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: context.l10n.travelAlbumNameHint,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: PomuColors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: PomuColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: PomuColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: PomuSpacing.md),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.travelStartSectionTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: PomuColors.textSecondary,
                  ),
                ),
                const SizedBox(height: PomuSpacing.sm),
                _DateTimeRow(
                  icon: Icons.calendar_today_rounded,
                  title: context.l10n.travelStartDate,
                  value: _formatDate(context, _startDate),
                  isEmpty: _startDate == null,
                  onTap: _pickStartDate,
                ),
                const Divider(height: 28),
                _DateTimeRow(
                  icon: Icons.schedule_rounded,
                  title: context.l10n.travelStartTime,
                  value: _formatTime(context, _startTime),
                  onTap: _pickStartTime,
                ),
              ],
            ),
          ),
          const SizedBox(height: PomuSpacing.md),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.travelEndSectionTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: PomuColors.textSecondary,
                  ),
                ),
                const SizedBox(height: PomuSpacing.sm),
                _DateTimeRow(
                  icon: Icons.event_available_rounded,
                  title: context.l10n.travelEndDate,
                  value: _formatDate(context, _endDate),
                  isEmpty: _endDate == null,
                  onTap: _pickEndDate,
                ),
                const Divider(height: 28),
                _DateTimeRow(
                  icon: Icons.schedule_rounded,
                  title: context.l10n.travelEndTime,
                  value: _formatTime(context, _endTime),
                  onTap: _pickEndTime,
                ),
              ],
            ),
          ),
          const SizedBox(height: PomuSpacing.md),
          const _InfoBox(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(PomuSpacing.lg),
          child: PomuPrimaryButton(
            text: _isLoading
                ? context.l10n.travelCreatingAlbum
                : context.l10n.travelCreateAlbum,
            icon: Icons.photo_album_outlined,
            onPressed: _isLoading ? null : _createAlbum,
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PomuSpacing.lg),
      decoration: BoxDecoration(
        color: PomuColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: PomuColors.divider),
      ),
      child: child,
    );
  }
}

class _DateTimeRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isEmpty;
  final VoidCallback onTap;

  const _DateTimeRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    this.isEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: PomuColors.primary),
            const SizedBox(width: PomuSpacing.sm),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: PomuColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isEmpty ? PomuColors.textSecondary : PomuColors.primary,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: PomuColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PomuSpacing.md),
      decoration: BoxDecoration(
        color: PomuColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: PomuColors.primary,
          ),
          SizedBox(width: PomuSpacing.sm),
          Expanded(
            child: Text(
              context.l10n.travelInfoDescription,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: PomuColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
