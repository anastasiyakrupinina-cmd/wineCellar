import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'get_it.config.dart';

final getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() => getIt.init();
