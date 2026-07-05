import 'package:flutter/material.dart';

import '../../core/theme/pomu_colors.dart';
import '../../core/theme/pomu_spacing.dart';
import '../../core/widgets/buttons/pomu_primary_button.dart';
import '../../services/travel_album_builder.dart';

class CreateTravelAlbumScreen extends StatefulWidget {
  const CreateTravelAlbumScreen({super.key});

  @override
  State<CreateTravelAlbumScreen> createState() =>
      _CreateTravelAlbumScreenState();
}

class _CreateTravelAlbumScreenState extends State<CreateTravelAlbumScreen> {
  final TravelAlbumBuilder _builder = TravelAlbumBuilder();
  final TextEditingController _albumNameController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
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

  Future<DateTime?> _pickDate({required DateTime initialDate}) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
  }

  Future<void> _createAlbum() async {
    final albumName = _albumNameController.text.trim();

    if (albumName.isEmpty || _startDate == null || _endDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('앨범 이름과 날짜를 모두 입력해주세요')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final album = await _builder.buildTravelAlbum(
        albumName: albumName,
        startDate: _startDate!,
        endDate: _endDate!,
      );

      if (!mounted) return;

      if (album.photos.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('선택한 기간에 사진이 없어요')));
        setState(() => _isLoading = false);
        return;
      }

      await _builder.createTravelAlbum(
        albumName: albumName,
        startDate: _startDate!,
        endDate: _endDate!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${album.photos.length}장의 사진으로 앨범을 만들었어요')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('앨범 생성 중 문제가 발생했어요: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '날짜 선택';
    return '${date.year}.${date.month}.${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PomuColors.background,
      appBar: AppBar(
        backgroundColor: PomuColors.background,
        elevation: 0,
        title: const Text(
          '여행 앨범 만들기',
          style: TextStyle(
            color: PomuColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(PomuSpacing.lg),
        children: [
          const Text(
            '여행 기간을 선택하면\n그날의 사진을 앨범으로 묶어드릴게요.',
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
                const Text(
                  '앨범 이름',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: PomuColors.textSecondary,
                  ),
                ),
                const SizedBox(height: PomuSpacing.sm),
                TextField(
                  controller: _albumNameController,
                  decoration: InputDecoration(
                    hintText: '예: 제주도 여행',
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
              children: [
                _DateRow(
                  title: '시작 날짜',
                  value: _formatDate(_startDate),
                  onTap: _pickStartDate,
                ),
                const Divider(height: 28),
                _DateRow(
                  title: '종료 날짜',
                  value: _formatDate(_endDate),
                  onTap: _pickEndDate,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(PomuSpacing.lg),
          child: PomuPrimaryButton(
            text: _isLoading ? '앨범 생성 중...' : '여행 앨범 만들기',
            icon: Icons.flight_takeoff_rounded,
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

class _DateRow extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback onTap;

  const _DateRow({
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = value == '날짜 선택';

    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
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
    );
  }
}
