class ProductVariant {
  String category;
  Map<String, List<String>> variants;

  ProductVariant({required this.category, required this.variants});

  // Fungsi untuk mengambil varian berdasarkan kategori
  static ProductVariant fromCategory(String category) {
    final lowerCategory = category.toLowerCase();
    if (_variantData.containsKey(lowerCategory)) {
      final data = _variantData[lowerCategory]!;
      return ProductVariant(category: data['category'] as String, variants: data['variants'] as Map<String, List<String>>);
    } else {
      throw Exception('Category not supported');
    }
  }

  // Fungsi untuk mendapatkan varian tertentu
  String? getVariant(String attribute) {
    if (variants.containsKey(attribute)) {
      return variants[attribute]?.join(', ');
    }
    return null;
  }

  // Data varian berdasarkan kategori
  static final Map<String, Map<String, dynamic>> _variantData = {
    'hp': {
      'category': 'HP',
      'variants': {
        'RAM': ['4GB', '6GB', '8GB', '12GB', '16GB'],
        'Memory': ['64GB', '128GB', '256GB', '512GB'],
        'Kamera': ['12MP', '16MP', '20MP', '48MP', '108MP'],
        'Warna': ['Hitam', 'Putih', 'Merah', 'Biru', 'Emas'],
        'Layar': ['6.1 inch', '6.5 inch', '6.8 inch'],
      },
    },
    'tablet': {
      'category': 'Tablet',
      'variants': {
        'RAM': ['2GB', '4GB', '6GB', '8GB'],
        'Memory': ['16GB', '32GB', '64GB', '128GB'],
        'Kamera': ['5MP', '8MP', '13MP'],
        'Lebar': ['7 inch', '10 inch', '12 inch', '14 inch'],
        'Warna': ['Hitam', 'Putih', 'Silver'],
      },
    },
    'laptop': {
      'category': 'Laptop',
      'variants': {
        'RAM': ['8GB', '16GB', '32GB', '64GB'],
        'Memory': ['512GB SSD', '1TB SSD', '2TB HDD'],
        'Kamera': ['HD', 'Full HD', '4K'],
        'Lebar': ['13 inch', '15 inch', '17 inch', '18.5 inch'],
        'Warna': ['Hitam', 'Perak', 'Emas'],
      },
    },
    'tv': {
      'category': 'TV',
      'variants': {
        'Ukuran': ['32 inch', '42 inch', '50 inch', '55 inch', '65 inch'],
        'Resolusi': ['HD', 'Full HD', '4K', '8K'],
        'Tinggi': ['60cm', '75cm', '90cm', '110cm'],
        'Smart_tv': ['Ya', 'Tidak'],
        'Type': ['LED', 'OLED', 'QLED'],
      },
    },
    'radio': {
      'category': 'Radio',
      'variants': {
        'Frekuensi': ['FM', 'AM', 'DAB'],
        'Teknologi': ['Analog', 'Digital'],
        'Baterai': ['AA', 'AAA', 'Baterai Rechargeable'],
        'Port': ['USB', 'Jack 3.5mm', 'Bluetooth'],
        'Speaker': ['Mono', 'Stereo'],
      },
    },
  };
}
