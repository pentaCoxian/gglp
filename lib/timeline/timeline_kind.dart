/// Per-account timeline targets exposed in .
///
/// Streaming channel keys mirror these in ; the string form is what
/// goes into `timeline_items.timelineKey` in Drift.
enum TimelineKind {
  home('home'),
  local('local'),
  hybrid('hybrid'),
  global('global');

  final String key;
  const TimelineKind(this.key);
}
