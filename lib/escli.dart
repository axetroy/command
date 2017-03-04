library escli;

import 'package:ee/ee.dart' show EventEmitter;
import 'option.dart' show Option;

num _max(List<num> numList) {
  num output = numList[0];
  numList.forEach((num num) {
    if (num > output) {
      output = num;
    }
  });
  return output;
}

String _repeat(String str, int times) {
  List<String> list = [];
  while (times != 0) {
    list.add(str);
    times--;
  }
  return list.join('');
}

class Commander extends EventEmitter {
  String $name = '';
  String $version = '';
  String $description = '';
  String $usage = '';

  List<Option> options = [];
  List<String> argv;
  List<Map> _argv = [];
  Map<String, Commander> subCommands = new Map();
  bool root = true;
  Commander parent;

  Map<String, String> $option = new Map();
  Map<String, String> $argv = new Map();

  Commander([String name]) {
    $name = name ?? '';
    this.option('-V, --version', 'print the current version');
    this.option('-h, --help', 'print the help info about ${$name}');
  }

  name(String name) {
    $name = name;
    return this;
  }

  version(String version) {
    $version = version;
    return this;
  }

  description(String description) {
    $description = description;
    return this;
  }

  usage(String usage) {
    $usage = usage;
    return this;
  }

  option(String flags, String description, [Function fn, dynamic defaultValue]) {
    final option = new Option(flags, description, fn, defaultValue);
    options.add(option);
    return this;
  }

  Commander command(String name, [String description, Map<String, dynamic> options]) {
    List<String> commands = name.split(new RegExp(r'\s+')).toList();
    String command = commands.removeAt(0);
    argv = commands;

    Commander subCommand = new Commander(command);
    subCommand.root = false;

    subCommand
      ..description(description ?? '')
      ..parseExpectedArgs(argv);

    subCommand.parent = this;
    subCommands[command] = subCommand;
    return subCommand;
  }

  Commander parseExpectedArgs(List<String> args) {
    if (args.length == 0) return this;
    int index = 0;
    args.forEach((arg) {
      Map<String, dynamic> argDetails = new Map();
      argDetails["name"] = "";
      argDetails["required"] = false;
      argDetails["variadic"] = false;
      argDetails["index"] = index;

      switch (arg[0]) {
        case '<':
          argDetails["required"] = true;
          argDetails["name"] = arg.trim().replaceAll(new RegExp(r'^[\s\S]|[\s\S]$'), '');
          break;
        case '[':
          argDetails["name"] = arg.replaceAll(new RegExp(r'^[\s\S]|[\s\S]$'), '');
          break;
      }

      final String name = argDetails["name"];

      if (name.length > 3 && name.substring(name.length - 3, name.length) == '...') {
        argDetails["variadic"] = true;
        argDetails["name"] = name.substring(name.length - 3, name.length);
      }

      if (name.isNotEmpty) {
        _argv.add(argDetails);
      }
      index++;
    });
    return this;
  }

  Commander action(Function handler) {
    this.on($name, (dynamic data) {
      handler($argv, $option);
    });
    return this;
  }

  void parseArgv(List<String> arguments) {
    arguments = arguments.toList();

    $option = new Map();
    $argv = new Map();

    //  parse options and set the value
    options.forEach((Option option) {
      option.parseArgv(arguments);
      $option[option.key] = option.value;
    });

    // parse argv and set the value
    _argv.forEach((Map argv) {
      final current = arguments[argv["index"]];
      $argv[argv["name"]] = current.indexOf('-') == 0 ? '' : current;
    });

    String command = arguments.removeAt(0);

    Commander subCommand = subCommands[command];

    if (subCommand == null) {
//      print('did not found any command and emite the own action');
      this.emit($name);
    }
    else {
      subCommand.parseArgv(arguments);
    }
  }

  void help() {
    num maxOptionLength = _max(options.map((Option op) => op.flags.length).toList());
    num maxCommandLength = _max(subCommands.values.map((Commander command) => command.$name.length).toList());

    String commands = subCommands.values.map((Commander command) {
      return '   ${command.$name} ${_repeat(' ', maxCommandLength - command.$name.length + 4)} ${command.$description}';
    }).join('\n');

    String optionsStr = options.map((Option op) {
      return '    ${op.flags} ${_repeat(' ', maxOptionLength - op.flags.length + 4)} ${op.description}';
    }).join('\n');

    print('''
Usage: ${$name} ${$usage}

  ${$description}

commands:
${commands}

options:
${optionsStr}
''');
  }

}