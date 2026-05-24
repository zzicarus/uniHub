enum ConsumptionStatus {
  unread('unread', '未看'),
  inProgress('in_progress', '进行中'),
  done('done', '已看'),
  archived('archived', '归档');

  const ConsumptionStatus(this.value, this.label);

  final String value;
  final String label;

  static ConsumptionStatus fromValue(String value) {
    return ConsumptionStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ConsumptionStatus.unread,
    );
  }
}
