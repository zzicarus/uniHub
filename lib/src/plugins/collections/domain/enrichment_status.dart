enum EnrichmentStatus {
  pending('pending', '等待中'),
  running('running', '抓取中'),
  success('success', '已完成'),
  failed('failed', '失败');

  const EnrichmentStatus(this.value, this.label);

  final String value;
  final String label;

  static EnrichmentStatus fromValue(String value) {
    return EnrichmentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => EnrichmentStatus.pending,
    );
  }
}
