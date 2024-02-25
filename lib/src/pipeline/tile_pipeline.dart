import 'dart:ui';

import '../logger.dart';
import '../symbols/text_painter.dart';
import '../themes/theme.dart';
import '../tile_source.dart';
import 'layer_pipeline_stage.dart';

class PipelineContext {
  final Canvas canvas;
  final TileSource tile;
  final Rect? clip;
  final double zoomScaleFactor;
  final double zoom;
  final double rotation;
  final TextPainterProvider painterProvider;
  final Logger logger;

  PipelineContext(
      {required this.canvas,
      required this.tile,
      required this.clip,
      required this.zoomScaleFactor,
      required this.zoom,
      required this.rotation,
      this.painterProvider = const DefaultTextPainterProvider(),
      this.logger = const Logger.noop()});
}

class TilePipeline {
  late final Theme theme;
  final TileSource tile;
  final double zoom;

  late final List<PipelineStage> stages;

  TilePipeline({required Theme theme, required this.tile, required this.zoom}) {
    this.theme = theme.copyWith(atZoom: zoom);
    List<List<ThemeLayer>> layerGroups = _group(theme.layers);
    final allStages =
        layerGroups.map((e) => LayerPipelineStage(layers: e)).toList();
    stages = tile.tileset.tiles.isEmpty ? [] : allStages;
  }
}

abstract class PipelineStage {
  final String id;
  abstract final Set<ThemeLayerType> layerTypes;

  PipelineStage({required this.id});

  void apply(PipelineContext context);
}

List<List<ThemeLayer>> _group(List<ThemeLayer> layers) {
  final groups = <List<ThemeLayer>>[];
  var currentGroup = <ThemeLayer>[];
  groups.add(currentGroup);
  for (final layer in layers) {
    if (currentGroup.isNotEmpty &&
        (layer.type != currentGroup.first.type ||
            !layer.id.startsWith(currentGroup.first.id.firstWord))) {
      currentGroup = [];
      groups.add(currentGroup);
    }
    currentGroup.add(layer);
  }
  return groups;
}

final _splitPattern = RegExp(r'[_-]');

extension _StringExtension on String {
  String get firstWord => split(_splitPattern).firstOrNull ?? this;
}
