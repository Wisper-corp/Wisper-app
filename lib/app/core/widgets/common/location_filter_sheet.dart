import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The value meaning "only things in my own location".
///
/// It sits alongside the job location types rather than beside them because
/// that is how it reads to someone using it: one list of places to look, of
/// which "near me" is a choice.
const String kLocalFilterValue = 'LOCAL';

/// A location filter, as a set rather than a pile of loose arguments — adding
/// a filter later means one field here and one row in the sheet, not another
/// control competing for space above the listings.
class LocationFilters {
  /// null means any location.
  final String? value;

  const LocationFilters({this.value});

  bool get isEmpty => value == null;

  /// Whether to ask the server for things near the signed-in person.
  bool get isLocal => value == kLocalFilterValue;

  /// The job location type to send, if the choice was one. "Local" is not a
  /// location *type* — it is a different question — so it is sent separately.
  String? get locationType => isLocal ? null : value;

  LocationFilters copyWith({Object? value = _unset}) => LocationFilters(
        value: value == _unset ? this.value : value as String?,
      );

  static const Object _unset = Object();
}

/// Opens the filter sheet. Returns the chosen filters, or null if dismissed.
Future<LocationFilters?> showLocationFilterSheet(
  BuildContext context, {
  required LocationFilters current,
  required Map<String?, String> options,
  required String ctaLabel,
}) {
  return showModalBottomSheet<LocationFilters>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _LocationFilterSheet(
      initial: current,
      options: options,
      ctaLabel: ctaLabel,
    ),
  );
}

class _LocationFilterSheet extends StatefulWidget {
  final LocationFilters initial;
  final Map<String?, String> options;
  final String ctaLabel;

  const _LocationFilterSheet({
    required this.initial,
    required this.options,
    required this.ctaLabel,
  });

  @override
  State<_LocationFilterSheet> createState() => _LocationFilterSheetState();
}

class _LocationFilterSheetState extends State<_LocationFilterSheet> {
  late LocationFilters _filters = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff121417),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      padding: EdgeInsets.only(top: 12.h),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: const Color(0xff3A4048),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 18.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                children: [
                  Text(
                    'Filters',
                    style: TextStyle(
                      fontFamily: 'Segoe UI',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  if (!_filters.isEmpty)
                    GestureDetector(
                      onTap: () =>
                          setState(() => _filters = const LocationFilters()),
                      behavior: HitTestBehavior.opaque,
                      child: Text(
                        'Clear all',
                        style: TextStyle(
                          fontFamily: 'Segoe UI',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xff4DA3F5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            Padding(
              padding: EdgeInsets.only(left: 20.w, bottom: 10.h),
              child: Text(
                'LOCATION',
                style: TextStyle(
                  fontFamily: 'Segoe UI',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: const Color(0xff8B949E),
                ),
              ),
            ),
            for (final entry in widget.options.entries)
              _Option(
                label: entry.value,
                selected: _filters.value == entry.key,
                onTap: () =>
                    setState(() => _filters = _filters.copyWith(value: entry.key)),
              ),
            SizedBox(height: 20.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_filters),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff168DE1),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                  ),
                  child: Text(
                    widget.ctaLabel,
                    style: TextStyle(
                      fontFamily: 'Segoe UI',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Option({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 13.h),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Segoe UI',
                  fontSize: 15.sp,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? Colors.white : const Color(0xffC9D1D9),
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_rounded,
                  size: 20.sp, color: const Color(0xff4DA3F5)),
          ],
        ),
      ),
    );
  }
}

/// The compact button that opens the sheet, beside a search field.
class FilterIconButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const FilterIconButton({
    super.key,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 48.w,
        height: 48.h,
        decoration: BoxDecoration(
          color: active ? const Color(0xff1E3A57) : const Color(0xff1B1E22),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: active ? const Color(0xff168DE1) : const Color(0xff2A2F35),
            width: active ? 1.2 : 0.8,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 21.sp,
              color: active ? const Color(0xff4DA3F5) : const Color(0xffC9D1D9),
            ),
            // A dot rather than a number: with one filter today a count reads
            // as clutter, and the dot still says "something is on".
            if (active)
              Positioned(
                top: 11.h,
                right: 11.w,
                child: Container(
                  width: 7.r,
                  height: 7.r,
                  decoration: const BoxDecoration(
                    color: Color(0xff4DA3F5),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The choices offered on the Jobs tab. "Local jobs" sits with the rest
/// because to someone filtering, "near me" is just another place to look.
const Map<String?, String> kJobLocationOptions = {
  null: 'Any location',
  kLocalFilterValue: 'Local jobs',
  'REMOTE': 'Remote',
  'ON_SITE': 'On-site',
  'HYBRID': 'Hybrid',
};

/// Services have no remote/on-site distinction — a service post carries no
/// location of its own, only the person offering it.
const Map<String?, String> kServiceLocationOptions = {
  null: 'Any location',
  kLocalFilterValue: 'Local services',
};
