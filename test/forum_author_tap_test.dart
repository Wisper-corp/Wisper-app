import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/modules/forum/model/forum_post_model.dart';
import 'package:wisper/app/modules/forum/widget/author_tap.dart';

/// Tapping an author's name and picture on a forum post opens their profile.
/// A person and a business have different screens, and the flattened author on
/// a post used to carry nothing that told them apart.
void main() {
  test('a person goes to the person profile', () {
    expect(
      forumAuthorDestination(
        const ForumAuthor(id: 'abc', name: 'Aisha Khan', isPerson: true),
      ),
      ForumAuthorDestination.person,
    );
  });

  test('a business goes to the business profile', () {
    expect(
      forumAuthorDestination(
        const ForumAuthor(id: 'abc', name: 'Acme Ltd', isPerson: false),
      ),
      ForumAuthorDestination.business,
    );
  });

  test('an author with no id goes nowhere', () {
    // Better than pushing a profile screen that can only fail to load.
    for (final author in [
      const ForumAuthor(name: 'Nameless'),
      const ForumAuthor(id: '', name: 'Empty'),
      const ForumAuthor(id: '   ', name: 'Blank'),
    ]) {
      expect(forumAuthorDestination(author), ForumAuthorDestination.none);
    }
  });

  test('isPerson is read from the payload, defaulting to a person', () {
    // Shape taken from GET /forum/group/:id — verified against the live API.
    final person = ForumAuthor.fromJson({
      'id': 'f7cd62cd-cf28-4224-80a0-0faadf052323',
      'name': 'Aisha Khan',
      'image': 'https://example.test/a.png',
      'title': 'Full-Stack Engineer, 8+ yrs exp',
      'isPerson': true,
    });
    expect(person.isPerson, isTrue);
    expect(forumAuthorDestination(person), ForumAuthorDestination.person);

    final business = ForumAuthor.fromJson({
      'id': 'b1',
      'name': 'Acme Ltd',
      'isPerson': false,
    });
    expect(forumAuthorDestination(business), ForumAuthorDestination.business);

    // An older server that does not send the flag must not break the tap.
    final legacy = ForumAuthor.fromJson({'id': 'c1', 'name': 'Someone'});
    expect(legacy.isPerson, isTrue);
    expect(forumAuthorDestination(legacy), ForumAuthorDestination.person);
  });
}
