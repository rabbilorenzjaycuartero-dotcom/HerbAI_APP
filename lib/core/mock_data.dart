import '../models/plant_model.dart';

class MockData {
  static List<Plant> getPlants() {
    return [
      Plant(
        id: '1',
        name: 'Aloe Vera',
        scientificName: 'Aloe barbadensis',
        description:
            'Aloe vera is a succulent plant species of the genus Aloe. It is widely used in traditional medicine for its healing properties.',
        rating: 4.8,
        reviewCount: 124,
        medicinalUses: [
          'Skin hydration',
          'Burn treatment',
          'Wound healing',
          'Anti-inflammatory'
        ],
        preparationMethods: [
          'Apply fresh gel directly to skin',
          'Mix with water for a soothing drink',
          'Add to lotions and creams'
        ],
        safetyWarnings: [
          'Do not consume internally without consulting a healthcare provider',
          'May cause allergic reactions in some individuals'
        ],
        ethnobotanicalInfo:
            'Used for thousands of years in Egyptian, Greek, and Chinese medicine.',
        imageUrl: 'https://coresg-normal.trae.ai/api/v1/text_to_image?prompt=aloe%20vera%20plant%20in%20pot&image_size=square_hd',
        categories: ['Skin Problems'],
        symptomsHelped: ['Skin Rash', 'Wounds'],
        availability: AvailabilityStatus.common,
        safetyInfo: const SafetyInfo(
          safeForAdults: true,
          safeForChildren: true,
          safeForElderly: true,
          safeForPregnant: false,
        ),
      ),
      Plant(
        id: '2',
        name: 'Peppermint',
        scientificName: 'Mentha × piperita',
        description:
            'Peppermint is a hybrid mint, a cross between watermint and spearmint. It has a refreshing aroma and is commonly used in culinary and medicinal applications.',
        rating: 4.6,
        reviewCount: 89,
        medicinalUses: [
          'Digestive aid',
          'Headache relief',
          'Nausea reduction',
          'Cooling sensation'
        ],
        preparationMethods: [
          'Steep leaves in hot water for tea',
          'Use essential oil in aromatherapy',
          'Add fresh leaves to food and drinks'
        ],
        safetyWarnings: [
          'May interact with certain medications',
          'Avoid excessive consumption during pregnancy'
        ],
        ethnobotanicalInfo:
            'Used since ancient times in Europe and Asia for its medicinal properties.',
        imageUrl: 'https://coresg-normal.trae.ai/api/v1/text_to_image?prompt=peppermint%20plant%20fresh%20leaves&image_size=square_hd',
        categories: ['Headache', 'Stomach Pain'],
        symptomsHelped: ['Headache', 'Stomach Pain', 'Diarrhea', 'Cold'],
        availability: AvailabilityStatus.common,
        safetyInfo: const SafetyInfo(
          safeForAdults: true,
          safeForChildren: true,
          safeForElderly: true,
          safeForPregnant: false,
        ),
      ),
      Plant(
        id: '3',
        name: 'Ginger',
        scientificName: 'Zingiber officinale',
        description:
            'Ginger is a flowering plant whose rhizome is widely used as a spice and a folk medicine. It has a warm, spicy flavor.',
        rating: 4.9,
        reviewCount: 156,
        medicinalUses: [
          'Anti-nausea',
          'Anti-inflammatory',
          'Digestive health',
          'Immune support'
        ],
        preparationMethods: [
          'Make tea by boiling sliced ginger',
          'Add to cooking',
          'Take as a supplement'
        ],
        safetyWarnings: [
          'May cause heartburn in some people',
          'Consult doctor if taking blood thinners'
        ],
        ethnobotanicalInfo:
            'Originated in Southeast Asia and has been used for over 5,000 years in traditional medicine.',
        imageUrl: 'https://coresg-normal.trae.ai/api/v1/text_to_image?prompt=ginger%20root%20fresh%20herb&image_size=square_hd',
        categories: ['Stomach Pain', 'Cough'],
        symptomsHelped: ['Cough', 'Cold', 'Sore Throat', 'Stomach Pain', 'Diarrhea'],
        availability: AvailabilityStatus.common,
        safetyInfo: const SafetyInfo(
          safeForAdults: true,
          safeForChildren: true,
          safeForElderly: true,
          safeForPregnant: false,
        ),
      ),
      Plant(
        id: '4',
        name: 'Chamomile',
        scientificName: 'Matricaria chamomilla',
        description:
            'Chamomile is an annual plant of the composite family. It is commonly used to make herbal tea for relaxation.',
        rating: 4.7,
        reviewCount: 98,
        medicinalUses: [
          'Sleep aid',
          'Anxiety reduction',
          'Digestive soothing',
          'Anti-inflammatory'
        ],
        preparationMethods: [
          'Steep flowers in hot water for tea',
          'Use in aromatherapy',
          'Apply topically for skin irritation'
        ],
        safetyWarnings: [
          'May cause allergic reactions in those allergic to daisies',
          'Avoid during pregnancy without medical advice'
        ],
        ethnobotanicalInfo:
            'Used in ancient Egypt, Greece, and Rome for its calming properties.',
        imageUrl: 'https://coresg-normal.trae.ai/api/v1/text_to_image?prompt=chamomile%20flowers%20herbal%20tea&image_size=square_hd',
        categories: ['Fever', 'Headache'],
        symptomsHelped: ['Fever', 'Headache', 'Cold', 'Stomach Pain'],
        availability: AvailabilityStatus.common,
        safetyInfo: const SafetyInfo(
          safeForAdults: true,
          safeForChildren: true,
          safeForElderly: true,
          safeForPregnant: false,
        ),
      ),
      Plant(
        id: '5',
        name: 'Lavender',
        scientificName: 'Lavandula angustifolia',
        description:
            'Lavender is a flowering plant in the mint family. It is known for its beautiful purple flowers and calming fragrance.',
        rating: 4.8,
        reviewCount: 142,
        medicinalUses: [
          'Stress relief',
          'Sleep improvement',
          'Pain management',
          'Antiseptic properties'
        ],
        preparationMethods: [
          'Use essential oil in diffuser',
          'Make herbal tea',
          'Add to bath water'
        ],
        safetyWarnings: [
          'Essential oil should be diluted before topical use',
          'May cause drowsiness'
        ],
        ethnobotanicalInfo:
            'Native to the Mediterranean region and used for over 2,500 years.',
        imageUrl: 'https://coresg-normal.trae.ai/api/v1/text_to_image?prompt=lavender%20flowers%20purple&image_size=square_hd',
        categories: ['Headache', 'Skin Problems'],
        symptomsHelped: ['Headache', 'Skin Rash', 'Body Pain', 'Cold'],
        availability: AvailabilityStatus.uncommon,
        safetyInfo: const SafetyInfo(
          safeForAdults: true,
          safeForChildren: false,
          safeForElderly: true,
          safeForPregnant: false,
        ),
      ),
      Plant(
        id: '6',
        name: 'Turmeric',
        scientificName: 'Curcuma longa',
        description:
            'Turmeric is a flowering plant of the ginger family. It is commonly used in Asian cuisine and traditional medicine.',
        rating: 4.9,
        reviewCount: 167,
        medicinalUses: [
          'Anti-inflammatory',
          'Antioxidant',
          'Pain relief',
          'Digestive health'
        ],
        preparationMethods: [
          'Add to curries and dishes',
          'Make golden milk',
          'Take as a supplement'
        ],
        safetyWarnings: [
          'May interact with certain medications',
          'Use in moderation'
        ],
        ethnobotanicalInfo:
            'Used in Ayurvedic medicine for over 4,000 years.',
        imageUrl: 'https://coresg-normal.trae.ai/api/v1/text_to_image?prompt=turmeric%20root%20powder&image_size=square_hd',
        categories: ['Skin Problems', 'Stomach Pain'],
        symptomsHelped: ['Skin Rash', 'Wounds', 'Body Pain', 'Stomach Pain', 'Cough'],
        availability: AvailabilityStatus.common,
        safetyInfo: const SafetyInfo(
          safeForAdults: true,
          safeForChildren: true,
          safeForElderly: true,
          safeForPregnant: false,
        ),
      ),
      Plant(
        id: '7',
        name: 'Lagundi',
        scientificName: 'Vitex negundo',
        description:
            'Lagundi is a common medicinal plant in the Philippines, widely used for respiratory issues.',
        rating: 4.8,
        reviewCount: 95,
        medicinalUses: [
          'Relieves cough',
          'Reduces fever',
          'Eases asthma symptoms'
        ],
        preparationMethods: [
          'Boil leaves for tea',
          'Use as decoction'
        ],
        safetyWarnings: [
          'Consult doctor if symptoms persist'
        ],
        ethnobotanicalInfo:
            'DOH-recommended herbal medicine in the Philippines.',
        imageUrl: 'https://coresg-normal.trae.ai/api/v1/text_to_image?prompt=lagundi%20plant%20leaves&image_size=square_hd',
        categories: ['Cough', 'Fever'],
        symptomsHelped: ['Cough', 'Fever', 'Sore Throat', 'Cold'],
        availability: AvailabilityStatus.common,
        safetyInfo: const SafetyInfo(
          safeForAdults: true,
          safeForChildren: true,
          safeForElderly: true,
          safeForPregnant: false,
        ),
        isDohRecognized: true,
        isEasyToPrepare: true,
      ),
      Plant(
        id: '8',
        name: 'Sambong',
        scientificName: 'Blumea balsamifera',
        description:
            'Sambong is a tropical shrub used for urinary tract issues and kidney stones.',
        rating: 4.7,
        reviewCount: 78,
        medicinalUses: [
          'Diuretic',
          'Relieves urinary problems',
          'Helps with kidney stones'
        ],
        preparationMethods: [
          'Boil leaves for tea'
        ],
        safetyWarnings: [
          'Consult doctor for kidney conditions'
        ],
        ethnobotanicalInfo:
            'DOH-recommended herbal medicine in the Philippines.',
        imageUrl: 'https://coresg-normal.trae.ai/api/v1/text_to_image?prompt=sambong%20plant%20leaves&image_size=square_hd',
        categories: ['Urinary Problems'],
        symptomsHelped: ['Urinary Problems', 'Body Pain'],
        availability: AvailabilityStatus.common,
        safetyInfo: const SafetyInfo(
          safeForAdults: true,
          safeForChildren: false,
          safeForElderly: true,
          safeForPregnant: false,
        ),
        isDohRecognized: true,
      ),
    ];
  }

  static List<Review> getReviews() {
    return [
      Review(
        id: '1',
        userName: 'Sarah Johnson',
        userAvatar: '',
        rating: 5.0,
        comment:
            'Aloe vera has been amazing for my dry skin! Highly recommend it.',
        date: DateTime(2024, 5, 15),
      ),
      Review(
        id: '2',
        userName: 'Michael Chen',
        userAvatar: '',
        rating: 4.0,
        comment: 'Great for soothing burns. Works really well.',
        date: DateTime(2024, 5, 10),
      ),
      Review(
        id: '3',
        userName: 'Emily Rodriguez',
        userAvatar: '',
        rating: 5.0,
        comment:
            'I use it every day. My skin has never looked better!',
        date: DateTime(2024, 5, 5),
      ),
    ];
  }

  static List<String> getRecentSearches() {
    return [
      'Aloe Vera',
      'Peppermint',
      'Skin Problems',
      'Headache Relief',
    ];
  }

  static String getDailyTip() {
    return 'Did you know? Peppermint oil can help relieve tension headaches when applied to the temples and forehead.';
  }
}
