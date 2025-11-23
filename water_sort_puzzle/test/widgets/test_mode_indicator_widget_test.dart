import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/models/test_mode_indicator.dart';
import 'package:water_sort_puzzle/widgets/test_mode_indicator_widget.dart';

void main() {
  group('TestModeIndicatorWidget', () {
    testWidgets('displays text, icon, and proper styling', (WidgetTester tester) async {
      const indicator = TestModeIndicator(
        text: 'TEST MODE',
        color: Colors.orange,
        icon: Icons.bug_report,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TestModeIndicatorWidget(indicator: indicator),
          ),
        ),
      );

      // Check that the text is displayed
      expect(find.text('TEST MODE'), findsOneWidget);
      
      // Check that the icon is displayed
      expect(find.byIcon(Icons.bug_report), findsOneWidget);
      
      // Check that the container exists
      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets('applies correct colors and styling', (WidgetTester tester) async {
      const indicator = TestModeIndicator(
        text: 'TEST MODE',
        color: Colors.orange,
        icon: Icons.bug_report,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TestModeIndicatorWidget(indicator: indicator),
          ),
        ),
      );

      // Find the container widget
      final containerWidget = tester.widget<Container>(find.byType(Container));
      final decoration = containerWidget.decoration as BoxDecoration;
      
      // Check background color (with opacity)
      expect(decoration.color, Colors.orange.withOpacity(0.2));
      
      // Check border color and width
      expect(decoration.border, isA<Border>());
      final border = decoration.border as Border;
      expect(border.top.color, Colors.orange);
      expect(border.top.width, 2);
      
      // Check border radius
      expect(decoration.borderRadius, BorderRadius.circular(20));

      // Check icon color and size
      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.bug_report));
      expect(iconWidget.color, Colors.orange);
      expect(iconWidget.size, 16);

      // Check text styling
      final textWidget = tester.widget<Text>(find.text('TEST MODE'));
      expect(textWidget.style?.color, Colors.orange);
      expect(textWidget.style?.fontWeight, FontWeight.bold);
      expect(textWidget.style?.fontSize, 12);
    });

    testWidgets('handles different colors correctly', (WidgetTester tester) async {
      const indicator = TestModeIndicator(
        text: 'DEBUG MODE',
        color: Colors.red,
        icon: Icons.developer_mode,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TestModeIndicatorWidget(indicator: indicator),
          ),
        ),
      );

      // Find the container widget
      final containerWidget = tester.widget<Container>(find.byType(Container));
      final decoration = containerWidget.decoration as BoxDecoration;
      
      // Check that red color is applied correctly
      expect(decoration.color, Colors.red.withOpacity(0.2));
      
      final border = decoration.border as Border;
      expect(border.top.color, Colors.red);

      // Check icon color
      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.developer_mode));
      expect(iconWidget.color, Colors.red);

      // Check text color
      final textWidget = tester.widget<Text>(find.text('DEBUG MODE'));
      expect(textWidget.style?.color, Colors.red);
    });

    testWidgets('handles different icons correctly', (WidgetTester tester) async {
      const indicator = TestModeIndicator(
        text: 'PREVIEW',
        color: Colors.blue,
        icon: Icons.preview,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TestModeIndicatorWidget(indicator: indicator),
          ),
        ),
      );

      // Check that the correct icon is displayed
      expect(find.byIcon(Icons.preview), findsOneWidget);
      expect(find.byIcon(Icons.bug_report), findsNothing);
      
      // Check that text is still displayed
      expect(find.text('PREVIEW'), findsOneWidget);
    });

    testWidgets('handles long text properly', (WidgetTester tester) async {
      const indicator = TestModeIndicator(
        text: 'VERY LONG TEST MODE TEXT',
        color: Colors.purple,
        icon: Icons.text_fields,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TestModeIndicatorWidget(indicator: indicator),
          ),
        ),
      );

      // Check that the long text is displayed
      expect(find.text('VERY LONG TEST MODE TEXT'), findsOneWidget);
      
      // Verify no overflow occurs
      expect(tester.takeException(), isNull);
    });

    testWidgets('has proper padding and spacing', (WidgetTester tester) async {
      const indicator = TestModeIndicator(
        text: 'TEST',
        color: Colors.green,
        icon: Icons.check,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TestModeIndicatorWidget(indicator: indicator),
          ),
        ),
      );

      // Find the container widget and check padding
      final containerWidget = tester.widget<Container>(find.byType(Container));
      expect(containerWidget.padding, const EdgeInsets.symmetric(horizontal: 12, vertical: 6));

      // Check that there's a SizedBox for spacing between icon and text
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final spacingSizedBox = sizedBoxes.firstWhere((box) => box.width == 4);
      expect(spacingSizedBox.width, 4);
    });

    testWidgets('uses Row with proper mainAxisSize', (WidgetTester tester) async {
      const indicator = TestModeIndicator(
        text: 'TEST',
        color: Colors.amber,
        icon: Icons.star,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TestModeIndicatorWidget(indicator: indicator),
          ),
        ),
      );

      // Check that Row is used with proper mainAxisSize
      final rowWidget = tester.widget<Row>(find.byType(Row));
      expect(rowWidget.mainAxisSize, MainAxisSize.min);
    });

    testWidgets('works with different screen sizes', (WidgetTester tester) async {
      const indicator = TestModeIndicator(
        text: 'RESPONSIVE TEST',
        color: Colors.teal,
        icon: Icons.phone_android,
      );

      // Test with small screen size
      await tester.binding.setSurfaceSize(const Size(300, 600));
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: TestModeIndicatorWidget(indicator: indicator),
            ),
          ),
        ),
      );

      expect(find.text('RESPONSIVE TEST'), findsOneWidget);
      expect(find.byIcon(Icons.phone_android), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Test with large screen size
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: TestModeIndicatorWidget(indicator: indicator),
            ),
          ),
        ),
      );

      expect(find.text('RESPONSIVE TEST'), findsOneWidget);
      expect(find.byIcon(Icons.phone_android), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Reset to default size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('maintains consistent styling across different indicators', (WidgetTester tester) async {
      const indicators = [
        TestModeIndicator(text: 'MODE 1', color: Colors.red, icon: Icons.looks_one),
        TestModeIndicator(text: 'MODE 2', color: Colors.blue, icon: Icons.looks_two),
        TestModeIndicator(text: 'MODE 3', color: Colors.green, icon: Icons.looks_3),
      ];

      for (final indicator in indicators) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TestModeIndicatorWidget(indicator: indicator),
            ),
          ),
        );

        // Check consistent styling elements
        final containerWidget = tester.widget<Container>(find.byType(Container));
        final decoration = containerWidget.decoration as BoxDecoration;
        
        // Border radius should be consistent
        expect(decoration.borderRadius, BorderRadius.circular(20));
        
        // Border width should be consistent
        final border = decoration.border as Border;
        expect(border.top.width, 2);
        
        // Padding should be consistent
        expect(containerWidget.padding, const EdgeInsets.symmetric(horizontal: 12, vertical: 6));
        
        // Icon size should be consistent
        final iconWidget = tester.widget<Icon>(find.byIcon(indicator.icon));
        expect(iconWidget.size, 16);
        
        // Text font size should be consistent
        final textWidget = tester.widget<Text>(find.text(indicator.text));
        expect(textWidget.style?.fontSize, 12);
        expect(textWidget.style?.fontWeight, FontWeight.bold);
      }
    });

    testWidgets('handles empty text gracefully', (WidgetTester tester) async {
      const indicator = TestModeIndicator(
        text: '',
        color: Colors.grey,
        icon: Icons.help,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TestModeIndicatorWidget(indicator: indicator),
          ),
        ),
      );

      // Should still display the icon and container
      expect(find.byIcon(Icons.help), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
      
      // Empty text should still be handled
      expect(find.text(''), findsOneWidget);
      
      // No exceptions should occur
      expect(tester.takeException(), isNull);
    });
  });
}