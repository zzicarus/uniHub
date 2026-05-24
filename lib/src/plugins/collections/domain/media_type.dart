enum MediaType {
  article('article', '文章'),
  video('video', '视频'),
  repository('repository', '代码仓库'),
  image('image', '图片'),
  unknown('unknown', '未知');

  const MediaType(this.value, this.label);

  final String value;
  final String label;

  static MediaType fromValue(String value) {
    return MediaType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => MediaType.unknown,
    );
  }
}
