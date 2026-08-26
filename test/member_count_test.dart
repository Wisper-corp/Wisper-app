import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/modules/chat/model/group_members_model.dart';

/// The members endpoint is paginated at 10. Counting the returned array
/// under-reports every community with more than a pageful — which is exactly
/// how a 32-member community displayed "10 members".
Map<String, dynamic> response({required int total, required int onPage}) => {
      'success': true,
      'message': 'ok',
      'data': {
        'meta': {'page': 1, 'limit': 10, 'total': total},
        'community': {'id': 'g1', 'name': 'Digital Remote Club STY'},
        'members': List.generate(
          onPage,
          (i) => {
            'id': 'm$i',
            'role': 'MEMBER',
            'auth': {
              'id': 'a$i',
              'person': {'name': 'Member $i', 'image': null},
            },
          },
        ),
      },
    };

void main() {
  test('meta.total is parsed, not the page length', () {
    final model = GroupMembersModel.fromJson(response(total: 32, onPage: 10));
    expect(model.data?.meta?.total, 32);
    expect(model.data?.members?.length, 10);
  });

  test('CONTROL: counting the page reports the wrong number', () {
    final model = GroupMembersModel.fromJson(response(total: 32, onPage: 10));
    final fromPage = model.data?.members?.length ?? 0;
    final fromMeta = model.data?.meta?.total ?? 0;
    expect(fromPage, isNot(fromMeta),
        reason: 'the two disagree once a community exceeds one page — '
            'this is the bug the fix removes');
    expect(fromPage, 10);
    expect(fromMeta, 32);
  });

  test('a small community reports the same either way', () {
    final model = GroupMembersModel.fromJson(response(total: 2, onPage: 2));
    expect(model.data?.meta?.total, 2);
    expect(model.data?.members?.length, 2);
    // Why nobody noticed until agents were seeded.
  });

  test('the overflow chip counts against the total, not the page', () {
    final model = GroupMembersModel.fromJson(response(total: 32, onPage: 10));
    final total = model.data?.meta?.total ?? 0;
    final preview = (model.data?.members ?? []).take(5).length;
    expect(total - preview, 27, reason: '"+27", not "+5"');
  });

  test('a missing meta falls back to the page rather than showing zero', () {
    final raw = response(total: 5, onPage: 5);
    (raw['data'] as Map).remove('meta');
    final model = GroupMembersModel.fromJson(raw);
    final fallback =
        model.data?.meta?.total ?? model.data?.members?.length ?? 0;
    expect(fallback, 5);
  });
}
