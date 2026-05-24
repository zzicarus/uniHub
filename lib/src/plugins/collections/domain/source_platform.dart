enum SourcePlatform {
  web('web', '网页'),
  wechat('wechat', '微信'),
  bilibili('bilibili', 'Bilibili'),
  youtube('youtube', 'YouTube'),
  github('github', 'GitHub'),
  zhihu('zhihu', '知乎'),
  xiaohongshu('xiaohongshu', '小红书'),
  twitter('twitter', 'Twitter'),
  douban('douban', '豆瓣'),
  pdf('pdf', 'PDF'),
  localFile('local_file', '本地文件'),
  unknown('unknown', '未知');

  const SourcePlatform(this.value, this.label);

  final String value;
  final String label;

  static SourcePlatform fromValue(String value) {
    return SourcePlatform.values.firstWhere(
      (platform) => platform.value == value,
      orElse: () => SourcePlatform.unknown,
    );
  }
}
