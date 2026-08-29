import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/widgets/common/searchable_choice_field.dart';
import 'package:wisper/app/urls.dart';

/// Career title, from the shared list or your own.
///
/// The list is long but never complete — someone whose title is not in it was
/// previously forced to pick one that is not true.
class JobTitleSearchField extends StatelessWidget {
  final String? initialValue;
  final Function(String) onSelected;
  final String hintText;

  const JobTitleSearchField({
    super.key,
    this.initialValue,
    required this.onSelected,
    this.hintText = 'Search job title...',
  });

  static Future<List<String>> searchTitles(String query) async {
    final response = await Get.find<NetworkCaller>().getRequest(
      Urls.jobTitleSearchUrl(query),
    );
    if (!response.isSuccess || response.responseData == null) return const [];
    final data = response.responseData['data'];
    if (data is! List) return const [];
    return data.map((e) => e.toString()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SearchableChoiceField(
      initialValue: initialValue,
      hintText: hintText,
      icon: Icons.work_outline,
      onSelected: onSelected,
      search: searchTitles,
    );
  }
}
