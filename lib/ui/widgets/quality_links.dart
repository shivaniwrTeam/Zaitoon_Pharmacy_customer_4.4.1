import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import "dart:collection";

class QualityLinks {
  String videoId;
  QualityLinks(this.videoId);
  getQualitiesSync() {
    return getQualitiesAsync();
  }

  Future<SplayTreeMap?> getQualitiesAsync() async {
    try {
      final response = await http
          .get(Uri.parse('https://player.vimeo.com/video/$videoId/config'));
      final jsonData =
          jsonDecode(response.body)['request']['files']['progressive'];
      final SplayTreeMap videoList = SplayTreeMap.fromIterable(
        jsonData,
        key: (item) => "${item['quality']} ${item['fps']}",
        value: (item) => item['url'],
      );
      return videoList;
    } catch (error) {
      return null;
    }
  }
}
