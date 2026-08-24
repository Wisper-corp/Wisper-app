import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/core/utils/collapsible_header.dart';

FixedScrollMetrics metrics({
  required double pixels,
  double max = 2000,
  AxisDirection axis = AxisDirection.down,
}) =>
    FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: max,
      pixels: pixels,
      viewportDimension: 600,
      axisDirection: axis,
      devicePixelRatio: 2,
    );

void main() {
  test('scrolling down collapses', () {
    expect(
      headerCollapseIntent(metrics: metrics(pixels: 300), scrollDelta: 20),
      isTrue,
    );
  });

  test('scrolling up expands', () {
    expect(
      headerCollapseIntent(metrics: metrics(pixels: 300), scrollDelta: -20),
      isFalse,
    );
  });

  test('at the top the bar is always fully visible', () {
    // Even a downward drag must not collapse it inside the expand zone.
    expect(
      headerCollapseIntent(metrics: metrics(pixels: 0), scrollDelta: 50),
      isFalse,
    );
    expect(
      headerCollapseIntent(metrics: metrics(pixels: 10), scrollDelta: 50),
      isFalse,
    );
  });

  test('overscrolling past the top keeps it expanded', () {
    expect(
      headerCollapseIntent(metrics: metrics(pixels: -80), scrollDelta: 30),
      isFalse,
    );
  });

  test('a list too short to scroll never collapses', () {
    expect(
      headerCollapseIntent(metrics: metrics(pixels: 0, max: 0), scrollDelta: 99),
      isFalse,
    );
  });

  test('tiny jitter is ignored', () {
    expect(
      headerCollapseIntent(metrics: metrics(pixels: 300), scrollDelta: 2),
      isNull,
    );
    expect(
      headerCollapseIntent(metrics: metrics(pixels: 300), scrollDelta: -2),
      isNull,
    );
  });

  test('a reversed viewport is not driven backwards', () {
    // Same delta as the first test, but the viewport is reversed, so the
    // finger moved the other way and the answer must invert.
    expect(
      headerCollapseIntent(
        metrics: metrics(pixels: 300, axis: AxisDirection.up),
        scrollDelta: 20,
      ),
      isFalse,
      reason: 'a reversed list must not collapse on an upward drag',
    );
    expect(
      headerCollapseIntent(
        metrics: metrics(pixels: 300, axis: AxisDirection.up),
        scrollDelta: -20,
      ),
      isTrue,
    );
  });

  test('CONTROL: ignoring axisDirection would invert reversed lists', () {
    // The naive version everyone writes first.
    bool? naive(double delta) => delta > kHeaderScrollThreshold ? true : null;
    final reversed = metrics(pixels: 300, axis: AxisDirection.up);
    expect(naive(20), isTrue);
    expect(headerCollapseIntent(metrics: reversed, scrollDelta: 20), isFalse,
        reason: 'the fix must disagree with the naive version here');
  });
}
