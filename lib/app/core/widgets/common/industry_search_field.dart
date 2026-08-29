import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/widgets/common/searchable_choice_field.dart';
import 'package:wisper/app/urls.dart';

/// Business industry, from the shared list or your own.
class IndustrySearchField extends StatelessWidget {
  final String? initialValue;
  final Function(String) onSelected;
  final String hintText;

  const IndustrySearchField({
    super.key,
    this.initialValue,
    required this.onSelected,
    this.hintText = 'Search industry (e.g. Software Devel...)',
  });

  /// The endpoint returns objects carrying a sector as well as a name; only
  /// the name is stored on a profile.
  static Future<List<String>> searchIndustries(String query) async {
    final response = await Get.find<NetworkCaller>().getRequest(
      Urls.industrySearchUrl(query),
    );
    if (!response.isSuccess || response.responseData == null) return const [];
    final data = response.responseData['data'];
    if (data is! List) return const [];
    return data
        .map((e) => e is Map ? (e['name']?.toString() ?? '') : e.toString())
        .where((name) => name.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return SearchableChoiceField(
      initialValue: initialValue,
      hintText: hintText,
      icon: Icons.business_outlined,
      onSelected: onSelected,
      search: searchIndustries,
    );
  }
}
