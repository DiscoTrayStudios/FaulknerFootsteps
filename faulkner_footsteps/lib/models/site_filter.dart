/// SiteFilter represents a category or filter that can be applied to historical sites.
class SiteFilter {
  final String name;

  /// Create a new SiteFilter with the given name
  SiteFilter({required this.name});

  /// Compare filters by name
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SiteFilter && other.name == name;
  }

  /// Hash based on name
  @override
  int get hashCode => name.hashCode;

  /// String representation
  @override
  String toString() => 'SiteFilter: $name';
}
