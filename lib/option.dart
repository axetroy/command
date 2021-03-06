import 'package:ee/ee.dart' show EventEmitter;
import 'package:escli/utils.dart';

class Option extends EventEmitter {
  String flags;
  String long;
  String short;

  String name() => long..replaceAll(new RegExp('--'), '').replaceAll(new RegExp('no-'), '');
  String description;

  bool required = false;
  bool optional = true;
  bool requireValue = false;
  bool haveSetFlag = false;
  bool anti = false;

  List<Map> argv = [];

  String key;
  dynamic value = false;

  dynamic defaultValue;

  Option(String _flags, String _description, [ void handler(dynamic data), dynamic $defaultValue]) {
    flags = _flags;
    description = _description;
    required = flags.indexOf('<') >= 0;
    optional = flags.indexOf('[') >= 0;
    requireValue = required || optional;
    anti = flags.indexOf('-no-') >= 0;
    defaultValue = $defaultValue ?? null;

    List flagsList = flags.split(new RegExp(r'[ ,|]+'));

    if (flagsList.length > 1) short = flagsList.removeAt(0);

    long = flagsList.removeAt(0);
    key = camelcase(long);

    if (requireValue) value = $defaultValue ?? '';

    this.on('run_handler', ([dynamic data]) {
      if (handler is Function) {
        // if the options like this:
        // options: --from <dir>
        // arguments: --from --to etc...
        // you can see that, from don't have value, then it should not be trigger
        if ((requireValue == true && value != null && value != '') || requireValue == false) {
          handler(data);
        }
      }
    });
  }

  bool isOption(String arg) {
    return arg == short || arg == long;
  }

  dynamic parseArgv(List<String> _arguments) {
    List<String> arguments = _arguments.toList();
    while (arguments.length != 0) {
      String arv = arguments.removeAt(0);
      if ((arv == short || arv == long) && arv.isNotEmpty) {
        haveSetFlag = true;
        // not just a flag, need to set a value
        if (value is! bool) {
          // if loop to last element, then set the value to empty string
          if (arguments.isEmpty || arguments.last == arv) {
            value = defaultValue ?? '';
          }
          // not last in List, next element could be contain the value, or not
          else {
            String nextElement = arguments.removeAt(0);
            // next element still be a flag, example: --help or --force etc...
            if (new RegExp('^-+').hasMatch(nextElement)) {
              // recover the element was remove
              arguments.insert(0, nextElement);
              value = defaultValue ?? '';
            }
            else if (nextElement.isEmpty) {
              value = defaultValue ?? '';
            }
            else {
              value = nextElement;
            }
          }
        }
        // it just a flag, true or false
        else {
          value = true;
        }
      };
    }
    return value;
  }
}