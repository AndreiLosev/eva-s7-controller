void checkConfig(Map<dynamic, dynamic> config) {
  try {
    Uri.parseIPv4Address(config['ip']);
  } catch (_) {
    throw Exception("invalid ip addres ${config['ip']}");
  }

  if (config['port'] is! int) {
    throw Exception("invalid ip port ${config['port']}");
  }

  if (config['rack'] is! int) {
    throw Exception("invalid  rack ${config['rack']}");
  }

  if (config['slot'] is! int) {
    throw Exception("invalid  slot ${config['slot']}");
  }

  if (config['connection_type'] is! int || config['connection_type'] > 16) {
    throw Exception("invalid connection_type ${config['connection_type']}");
  }

  if (config['pull_cache_sec'] is! num) {
    throw Exception("invalid pull_cache_sec ${config['pull_cache_sec']}");
  }

  if (config['pull_interval'] is! num) {
    throw Exception("invalid pull_interval ${config['pull_interval']}");
  }

  if (config['pull'] is! List) {
    throw Exception("invalid pull, pull should be a list");
  }

  for (var pullItem in config['pull']) {
    final area = pullItem['area'];
    if (area is! String) {
      throw Exception("invalid pull item ${pullItem['area']}");
    }

    if (!(area.startsWith('DB') || ['M', "I", "Q"].contains(area))) {
      throw Exception("invalid pull item ${pullItem['area']}");
    }

    if (pullItem['map'] is! List) {
      throw Exception("invalid pull.map, pull.map should be a list");
    }
  }

  if (config['action_map'] is! Map) {
    throw Exception("invalid action_map, action_map should be a Map");
  }
}
