# Forest and Settlement Cluster System

## Overview

The cluster system adds dynamic forests and settlements to the game world. These features adapt to the chunk-based terrain expansion, creating natural-looking collections of trees and buildings that can span multiple chunks.

## Key Features

### 1. Cluster-Based Generation
- **Forests**: Collections of procedural low-poly trees
- **Settlements**: Collections of procedural low-poly buildings
- **Seamless Expansion**: Clusters grow naturally across chunk boundaries
- **Performance Optimized**: Minimal overhead for mobile devices

### 2. Procedural Models
- **Low-Poly Trees**: Simple cone canopy + cylinder trunk (< 100 vertices)
- **Low-Poly Buildings**: Box walls + pyramid roof with varied colors
- **Procedural Generation**: No external assets required
- **Mobile-Friendly**: Optimized geometry and materials

### 3. Intelligent Placement
- **Terrain-Aware**: Objects only placed on walkable terrain
- **Slope Checking**: Buildings require flatter ground (≤15°) than trees (≤30°)
- **Lake Avoidance**: No objects placed in water
- **Density-Based**: Number of objects scales with cluster density and influence

## Implementation Details

### Cluster System (`cluster_system.gd`)

The cluster system manages global cluster data:

```gdscript
# Get clusters affecting a chunk
var clusters = ClusterSystem.get_clusters_for_chunk(chunk_pos, world_seed)

# Check influence at a position
var influence = ClusterSystem.get_cluster_influence_at_pos(world_pos, cluster)
```

#### Cluster Generation Probabilities
- **Forest**: 15% chance per chunk
- **Settlement**: 5% chance per chunk (only if no forest)

#### Cluster Properties
- **Forest Radius**: 15-40 world units
- **Settlement Radius**: 12-25 world units
- **Density**: Random between type-specific ranges
- **Influence**: Smooth cosine falloff from center to edge

### Procedural Models (`procedural_models.gd`)

Static functions for creating models:

```gdscript
# Create a tree mesh
var tree_mesh = ProceduralModels.create_tree_mesh(seed_value)
var tree_material = ProceduralModels.create_tree_material()

# Create a building mesh
var building_mesh = ProceduralModels.create_building_mesh(seed_value)
var building_material = ProceduralModels.create_building_material()
```

#### Tree Components
- **Trunk**: Brown cylinder (6 segments)
- **Canopy**: Green cone (8 segments)
- **Variation**: Height and radius vary by ±20%

#### Building Components
- **Walls**: Colored box (4 faces)
- **Roof**: Pyramid with darker color
- **Size**: 3-6 units wide/deep, 2.5-5 units tall
- **Colors**: Beige, brown, light gray, or dark brown walls

### Chunk Integration

Clusters are integrated into chunk generation:

1. **Heightmap Generation**: Standard terrain generation
2. **Walkability Calculation**: Slope analysis
3. **Metadata Calculation**: Biome and landmark detection
4. **Cluster Lookup**: Check for clusters affecting this chunk
5. **Object Placement**: Place trees/buildings based on cluster influence

## Performance Optimization

### Mobile-First Design
- **Low Poly Count**: Trees ~50 vertices, Buildings ~30 vertices
- **Efficient Materials**: Simple StandardMaterial3D with vertex colors
- **Reduced Object Count**: Density multipliers keep counts reasonable
- **No Textures**: Vertex colors only, no texture lookups
- **Smart Placement**: Pre-check walkability and slope before placing

### Object Count Management
- **Forest Density**: ~2% of chunk area × density × influence
- **Settlement Density**: ~1.5% of chunk area × density × influence
- **Example**: 32×32 chunk with 50% forest influence @ 0.5 density = ~5 trees

### Memory Efficiency
- **Shared Meshes**: Could be implemented via mesh instancing
- **Dynamic Loading**: Objects only exist while chunk is loaded
- **Minimal Metadata**: Clusters store only essential data

## Usage Examples

### Enable Cluster Visualization
```gdscript
# In debug visualization
debug_visualization.toggle_clusters()
```

### Query Clusters in Area
```gdscript
# Check what clusters affect a chunk
var chunk_pos = Vector2i(0, 0)
var clusters = ClusterSystem.get_clusters_for_chunk(chunk_pos, world_seed)

for cluster in clusters:
    print("Cluster type: ", cluster.type)
    print("Cluster radius: ", cluster.radius)
    print("Cluster density: ", cluster.density)
```

### Check Cluster Influence
```gdscript
# Get influence value at world position
var world_pos = Vector2(100, 50)
for cluster in active_clusters:
    var influence = ClusterSystem.get_cluster_influence_at_pos(world_pos, cluster)
    if influence > 0:
        print("Position influenced by cluster: ", influence)
```

## Testing

Run cluster tests with:
```bash
godot --headless res://tests/test_clusters.tscn
```

Tests verify:
- ✓ Cluster generation across chunks
- ✓ Seed-based consistency
- ✓ Influence calculations
- ✓ Boundary crossing behavior
- ✓ Object placement

## Debugging

### Visual Debugging
1. Enable cluster visualization in debug overlay
2. Green circles = Forest clusters
3. Orange circles = Settlement clusters
4. Circle radius = Cluster influence range

### Console Debugging
```gdscript
# Print all active clusters
for cluster_key in ClusterSystem.all_clusters:
    var cluster = ClusterSystem.all_clusters[cluster_key]
    print("Cluster %d: %s at %s" % [cluster.cluster_id, 
          "Forest" if cluster.type == ClusterSystem.ClusterType.FOREST else "Settlement",
          cluster.center_chunk])
```

## Future Enhancements

Potential improvements:

### Performance
- [ ] Mesh instancing for identical trees/buildings
- [ ] LOD (Level of Detail) for distant objects
- [ ] Frustum culling optimization
- [ ] Object pooling for frequent load/unload

### Visual Quality
- [ ] More tree variations (pine, oak, palm)
- [ ] Building type variations (house, tower, barn)
- [ ] Simple texture atlas for variety
- [ ] Wind animation for tree canopies

### Gameplay Integration
- [ ] Harvestable trees for resources
- [ ] Enterable buildings
- [ ] NPC placement in settlements
- [ ] Roads connecting settlements

### Realism
- [ ] Biome-specific forests (pine in mountains, palm near water)
- [ ] Settlement placement near water sources
- [ ] Path networks within settlements
- [ ] Agricultural fields around settlements

## Technical Notes

### Seed-Based Generation
- Each cluster has a unique seed derived from world seed + position
- Objects within clusters use cluster seed for consistency
- Same chunk + same world seed = identical clusters and objects

### Chunk Boundary Handling
- Clusters can span multiple chunks
- Each chunk queries global cluster registry
- Influence smoothly fades across boundaries
- No visible seams between chunks

### Memory Management
- Clusters are stored globally (lightweight)
- Objects are created per-chunk (heavier)
- Objects freed when chunk unloads
- No memory leaks with proper cleanup

## API Reference

### ClusterSystem

#### Static Methods
- `get_clusters_for_chunk(chunk_pos: Vector2i, world_seed: int) -> Array[ClusterData]`
  - Returns all clusters affecting the given chunk
  
- `get_cluster_influence_at_pos(world_pos: Vector2, cluster: ClusterData) -> float`
  - Returns 0.0 to 1.0 influence value at position
  
- `clear_all_clusters()`
  - Removes all clusters (for testing/reset)

#### ClusterData Properties
- `cluster_id: int` - Unique cluster identifier
- `center_chunk: Vector2i` - Origin chunk coordinates
- `center_pos: Vector2` - Position within center chunk
- `type: ClusterType` - FOREST or SETTLEMENT
- `radius: float` - Influence radius in world units
- `density: float` - Object density (0.0 to 1.0)
- `seed_value: int` - Random seed for this cluster

### ProceduralModels

#### Static Methods
- `create_tree_mesh(seed_val: int) -> ArrayMesh`
  - Generates a low-poly tree mesh
  
- `create_building_mesh(seed_val: int) -> ArrayMesh`
  - Generates a low-poly building mesh
  
- `create_tree_material() -> StandardMaterial3D`
  - Creates material for trees
  
- `create_building_material() -> StandardMaterial3D`
  - Creates material for buildings

### Chunk Extensions

#### New Properties
- `placed_objects: Array` - Objects placed in this chunk
- `active_clusters: Array` - Clusters affecting this chunk

#### New Methods
- `_place_cluster_objects()` - Main cluster placement function
- `_place_forest_objects(cluster)` - Place trees
- `_place_settlement_objects(cluster)` - Place buildings

## License

Same as main project license.
