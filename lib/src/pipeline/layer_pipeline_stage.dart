import 'dart:ui';

import '../constants.dart';
import '../context.dart';
import '../features/feature_renderer.dart';
import '../optimizations.dart';
import '../profiling.dart';
import '../themes/theme.dart';
import 'tile_pipeline.dart';

class LayerPipelineStage extends PipelineStage {
  final List<ThemeLayer> layers;
  @override
  late final Set<ThemeLayerType> layerTypes;

  LayerPipelineStage({required this.layers})
      : super(id: '${layers.first.id}-${layers.last.id}') {
    layerTypes = layers.map((e) => e.type).toSet();
  }

  @override
  void apply(PipelineContext context) {
    profileSync('Render-$id', () {
      final tileSpace =
          Rect.fromLTWH(0, 0, tileSize.toDouble(), tileSize.toDouble());
      context.canvas.save();
      context.canvas.clipRect(tileSpace);
      final tileClip = context.clip ?? tileSpace;
      final optimizations = Optimizations(
          skipInBoundsChecks: context.clip == null ||
              (tileClip.width - tileSpace.width).abs() < (tileSpace.width / 2));
      final renderContext = Context(
          logger: context.logger,
          canvas: context.canvas,
          featureRenderer: FeatureDispatcher(context.logger),
          tileSource: context.tile,
          zoomScaleFactor: context.zoomScaleFactor,
          zoom: context.zoom,
          rotation: context.rotation,
          tileSpace: tileSpace,
          tileClip: tileClip,
          optimizations: optimizations,
          textPainterProvider: context.painterProvider);
      for (final themeLayer in layers) {
        context.logger.log(() => 'rendering theme layer ${themeLayer.id}');
        themeLayer.render(renderContext);
      }
      context.canvas.restore();
    });
  }
}
