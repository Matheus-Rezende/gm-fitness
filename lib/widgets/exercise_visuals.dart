import '../models/exercise.dart';
import '../motion/figure_painter.dart';
import '../state/app_state.dart';

/// Estilo do boneco para um exercício: corpo do perfil e músculos trabalhados.
FigureStyle figureStyleFor(AppState state, Exercise e) => FigureStyle(
      male: state.isMale,
      primary: {e.group},
      secondary: {for (final g in e.secondary) if (g != e.group) g},
    );
