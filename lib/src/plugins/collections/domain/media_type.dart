enum MediaType {
  article('article', '文章'),
  video('video', '视频'),
  repository('repository', '代码仓库'),
  webpage('webpage', '网页'),
  image('image', '图片'),
  pdf('pdf', 'PDF'),
  audio('audio', '音频'),
  post('post', '帖子'),
  document('document', '文档'),
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
