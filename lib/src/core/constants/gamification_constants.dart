class GamificationConstants {
  static const Map<String, int> pointValues = {
    'REGISTRATION': 10,
    'LIKE': 1,
    'UNLIKE': -1,
    'COMMENT': 3,
    'DELETE_COMMENT': -3,
    'CREATE_CONTENT': 25,
    'DELETE_CONTENT': -25,
    'PUBLISH_POST': 10,
    'DELETE_POST': -10,
    'RECEIVE_LIKE': 1,
    'RECEIVE_UNLIKE': -1,
    'RECEIVE_COMMENT': 2,
    'RECEIVE_DELETE_COMMENT': -2,
    'TESTIMONY': 5,
    'DELETE_TESTIMONY': -5,
    'RECEIVE_TESTIMONY': 5,
    'RECEIVE_DELETE_TESTIMONY': -5,
  };

  static const List<Map<String, dynamic>> tierThresholds = [
    {'level': 1, 'minPoints': 0, 'name': 'Beginner', 'icon': '🌱'},
    {'level': 2, 'minPoints': 101, 'name': 'Explorer', 'icon': '🧭'},
    {'level': 3, 'minPoints': 501, 'name': 'Active User', 'icon': '⚡'},
    {'level': 4, 'minPoints': 1001, 'name': 'Contributor', 'icon': '🖋️'},
    {'level': 5, 'minPoints': 2501, 'name': 'Elite Member', 'icon': '💎'},
    {'level': 6, 'minPoints': 5001, 'name': 'Power User', 'icon': '🔥'},
    {'level': 7, 'minPoints': 10001, 'name': 'Legend', 'icon': '👑'},
  ];

  static Map<String, dynamic> getTier(int points) {
    for (var i = tierThresholds.length - 1; i >= 0; i--) {
      if (points >= (tierThresholds[i]['minPoints'] as int)) {
        return tierThresholds[i];
      }
    }
    return tierThresholds[0];
  }
}
