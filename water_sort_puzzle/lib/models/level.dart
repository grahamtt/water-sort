import 'package:json_annotation/json_annotation.dart';
import 'container.dart';

part 'level.g.dart';

/// Represents a level in the water sort puzzle game
@JsonSerializable(explicitToJson: true)
class Level {
  /// Unique identifier for this level
  final int id;
  
  /// Difficulty rating (1-10, where 1 is easiest)
  final int difficulty;
  
  /// Number of containers in this level
  final int containerCount;
  
  /// Number of different colors used in this level
  final int colorCount;
  
  /// Initial state of containers for this level
  final List<Container> initialContainers;
  
  /// Minimum number of moves required to solve this level (if known)
  final int? minimumMoves;
  
  /// Maximum number of moves allowed (null for unlimited)
  final int? maxMoves;
  
  /// Whether this level has been validated as solvable
  final bool isValidated;
  
  /// Optional hint text for the player
  final String? hint;
  
  /// Tags for categorizing levels (e.g., 'tutorial', 'advanced', 'challenge')
  final List<String> tags;
  
  const Level({
    required this.id,
    required this.difficulty,
    required this.containerCount,
    required this.colorCount,
    required this.initialContainers,
    this.minimumMoves,
    this.maxMoves,
    this.isValidated = false,
    this.hint,
    this.tags = const [],
  });
  
  /// Create a copy of this level with optional parameter overrides
  Level copyWith({
    int? id,
    int? difficulty,
    int? containerCount,
    int? colorCount,
    List<Container>? initialContainers,
    int? minimumMoves,
    int? maxMoves,
    bool? isValidated,
    String? hint,
    List<String>? tags,
  }) {
    return Level(
      id: id ?? this.id,
      difficulty: difficulty ?? this.difficulty,
      containerCount: containerCount ?? this.containerCount,
      colorCount: colorCount ?? this.colorCount,
      initialContainers: initialContainers ?? List.from(this.initialContainers),
      minimumMoves: minimumMoves ?? this.minimumMoves,
      maxMoves: maxMoves ?? this.maxMoves,
      isValidated: isValidated ?? this.isValidated,
      hint: hint ?? this.hint,
      tags: tags ?? List.from(this.tags),
    );
  }
  
  /// Check if this level is a tutorial level
  bool get isTutorial => tags.contains('tutorial');
  
  /// Check if this level is a challenge level
  bool get isChallenge => tags.contains('challenge');
  
  /// Get the number of empty containers in this level
  int get emptyContainerCount {
    return initialContainers.where((container) => container.isEmpty).length;
  }
  
  /// Get the number of filled containers in this level
  int get filledContainerCount {
    return initialContainers.where((container) => !container.isEmpty).length;
  }
  
  /// Calculate the complexity score based on various factors
  double get complexityScore {
    double score = 0.0;
    
    // Base score from difficulty
    score += difficulty * 10;
    
    // // Add points for more containers
    // score += containerCount * 2;
    
    // Add points for more colors
    score += colorCount * 5;
    
    // Add points for fewer empty containers (makes it harder)
    score += (containerCount - emptyContainerCount) * 3;
    
    // Calculate average liquid layers per container
    int totalLayers = 0;
    for (final container in initialContainers) {
      if (!container.isEmpty) {
        totalLayers += container.colorSegmentCount;
      }
    }
    
    if (filledContainerCount > 0) {
      double avgLayers = totalLayers / filledContainerCount;
      score += avgLayers * 4;
    }
    
    return score;
  }
  
  /// Validate the level structure for basic consistency
  bool get isStructurallyValid {
    // Check that we have the expected number of containers
    if (initialContainers.length != containerCount) return false;
    
    // Check that all containers have valid IDs
    final containerIds = initialContainers.map((c) => c.id).toSet();
    if (containerIds.length != containerCount) return false;
    
    // Note: We don't require an empty container here because some puzzles
    // can be solved without one (e.g., when you can pour directly between
    // matching colors). The actual solvability check will determine if the
    // level is truly solvable.
    
    // Count actual colors used
    final colorsUsed = <String>{};
    for (final container in initialContainers) {
      for (final layer in container.liquidLayers) {
        colorsUsed.add(layer.color.name);
      }
    }
    
    // Check that the color count matches
    if (colorsUsed.length != colorCount) return false;
    
    // Check that each color appears in sufficient quantity
    // (each color should fill at least one complete container)
    final colorVolumes = <String, int>{};
    for (final container in initialContainers) {
      for (final layer in container.liquidLayers) {
        colorVolumes[layer.color.name] = 
            (colorVolumes[layer.color.name] ?? 0) + layer.volume;
      }
    }
    
    return true;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Level &&
        other.id == id &&
        other.difficulty == difficulty &&
        other.containerCount == containerCount &&
        other.colorCount == colorCount &&
        _listEquals(other.initialContainers, initialContainers) &&
        other.minimumMoves == minimumMoves &&
        other.maxMoves == maxMoves &&
        other.isValidated == isValidated &&
        other.hint == hint &&
        _listEquals(other.tags, tags);
  }
  
  @override
  int get hashCode => Object.hash(
    id,
    difficulty,
    containerCount,
    colorCount,
    Object.hashAll(initialContainers),
    minimumMoves,
    maxMoves,
    isValidated,
    hint,
    Object.hashAll(tags),
  );
  
  @override
  String toString() {
    return 'Level(id: $id, difficulty: $difficulty, containers: $containerCount, '
           'colors: $colorCount, validated: $isValidated)';
  }
  
  /// Helper method to compare lists
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
  
  /// JSON serialization
  factory Level.fromJson(Map<String, dynamic> json) => _$LevelFromJson(json);
  
  /// JSON deserialization
  Map<String, dynamic> toJson() => _$LevelToJson(this);
}