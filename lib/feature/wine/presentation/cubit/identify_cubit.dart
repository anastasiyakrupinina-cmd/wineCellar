import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_wine/feature/wine/presentation/cubit/identify_state.dart';

// Image identification feature removed. This cubit is kept as a stub.
class IdentifyWineCubit extends Cubit<IdentifyWineState> {
  IdentifyWineCubit() : super(IdentifyWineInitial());
}
