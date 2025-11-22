import 'package:flutter/material.dart';
import '../models/container.dart' as models;
import '../models/liquid_color.dart';
import '../models/liquid_layer.dart';
import 'container_widget.dart';

/// A demo widget to showcase the ContainerWidget functionality
class ContainerDemo extends StatefulWidget {
  const ContainerDemo({Key? key}) : super(key: key);
  
  @override
  State<ContainerDemo> createState() => _ContainerDemoState();
}

class _ContainerDemoState extends State<ContainerDemo> {
  int? selectedContainerId;
  late List<models.Container> containers;
  
  @override
  void initState() {
    super.initState();
    _initializeContainers();
  }
  
  void _initializeContainers() {
    containers = [
      models.Container(
        id: 1,
        capacity: 4,
        liquidLayers: [
          const LiquidLayer(color: LiquidColor.red, volume: 2),
          const LiquidLayer(color: LiquidColor.blue, volume: 1),
        ],
      ),
      models.Container(
        id: 2,
        capacity: 4,
        liquidLayers: [
          const LiquidLayer(color: LiquidColor.green, volume: 1),
          const LiquidLayer(color: LiquidColor.yellow, volume: 2),
        ],
      ),
      models.Container(
        id: 3,
        capacity: 4,
        liquidLayers: [],
      ),
      models.Container(
        id: 4,
        capacity: 4,
        liquidLayers: [
          const LiquidLayer(color: LiquidColor.purple, volume: 4),
        ],
      ),
    ];
  }
  
  void _handleContainerTap(int containerId) {
    setState(() {
      if (selectedContainerId == containerId) {
        // Deselect if tapping the same container
        selectedContainerId = null;
      } else {
        selectedContainerId = containerId;
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Container Widget Demo'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[50]!,
              Colors.blue[100]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Tap containers to select them',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,
                    children: containers.map((container) {
                      return ContainerWidget(
                        container: container,
                        isSelected: selectedContainerId == container.id,
                        onTap: () => _handleContainerTap(container.id),
                      );
                    }).toList(),
                  ),
                ),
              ),
              if (selectedContainerId != null)
                Container(
                  margin: const EdgeInsets.all(16.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildContainerInfo(),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildContainerInfo() {
    final selectedContainer = containers.firstWhere(
      (c) => c.id == selectedContainerId,
    );
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Container ${selectedContainer.id}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text('Capacity: ${selectedContainer.capacity}'),
        Text('Current Volume: ${selectedContainer.currentVolume}'),
        Text('Remaining Capacity: ${selectedContainer.remainingCapacity}'),
        Text('Is Empty: ${selectedContainer.isEmpty}'),
        Text('Is Full: ${selectedContainer.isFull}'),
        Text('Is Sorted: ${selectedContainer.isSorted}'),
        if (selectedContainer.topColor != null)
          Text('Top Color: ${selectedContainer.topColor!.displayName}'),
        const SizedBox(height: 8),
        const Text(
          'Liquid Layers:',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        if (selectedContainer.isEmpty)
          const Text('  (empty)')
        else
          ...selectedContainer.liquidLayers.map((layer) => Text(
            '  ${layer.color.displayName}: ${layer.volume} units',
          )),
      ],
    );
  }
}