import 'package:flutter_test/flutter_test.dart';
import 'package:ai_herbal_app/providers/plant_provider.dart';

void main() {
  test('plant search is case-insensitive and favorites can be toggled', () {
    final provider = PlantProvider();

    final results = provider.searchPlants('aloe');
    expect(results, isNotEmpty);

    final plant = results.first;
    provider.toggleFavorite(plant);
    expect(provider.isFavorite(plant), isTrue);

    provider.toggleFavorite(plant);
    expect(provider.isFavorite(plant), isFalse);
  });
}
