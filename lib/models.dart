// ─── alert.dart ───────────────────────────────────────────────────────────────
class Alert {
  final double? alertLatitude;
  final double? alertLongitude;
  final String? alertDisease;

  Alert({this.alertLatitude, this.alertLongitude, this.alertDisease});

  factory Alert.fromMap(Map<String, dynamic> map) => Alert(
        alertLatitude: (map['alertLatitude'] as num?)?.toDouble(),
        alertLongitude: (map['alertLongitude'] as num?)?.toDouble(),
        alertDisease: map['alertDisease'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'alertLatitude': alertLatitude,
        'alertLongitude': alertLongitude,
        'alertDisease': alertDisease,
      };
}

// ─── crop.dart ────────────────────────────────────────────────────────────────
class Crop {
  final String? cropName;
  final String? cropImage;
  final String? cropReference;

  Crop({this.cropName, this.cropImage, this.cropReference});

  factory Crop.fromMap(Map<String, dynamic> map) => Crop(
        cropName: map['cropName'] as String?,
        cropImage: map['cropImage'] as String?,
        cropReference: map['cropReference'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'cropName': cropName,
        'cropImage': cropImage,
        'cropReference': cropReference,
      };
}

// ─── disease.dart ─────────────────────────────────────────────────────────────
class Disease {
  final String? diseaseName;
  final String? diseaseCategory;
  final String? diseaseCrop;
  final String? diseaseSymptoms;
  final String? diseaseComments;
  final String? diseaseManagement;
  final String? diseaseImage;

  Disease({
    this.diseaseName,
    this.diseaseCategory,
    this.diseaseCrop,
    this.diseaseSymptoms,
    this.diseaseComments,
    this.diseaseManagement,
    this.diseaseImage,
  });

  factory Disease.fromMap(Map<String, dynamic> map) => Disease(
        diseaseName: map['diseaseName'] as String?,
        diseaseCategory: map['diseaseCategory'] as String?,
        diseaseCrop: map['diseaseCrop'] as String?,
        diseaseSymptoms: map['diseaseSymptoms'] as String?,
        diseaseComments: map['diseaseComments'] as String?,
        diseaseManagement: map['diseaseManagement'] as String?,
        diseaseImage: map['diseaseImage'] as String?,
      );
}

// ─── history.dart ─────────────────────────────────────────────────────────────
class History {
  final int? historyId;
  final String historyDisease;
  final String historyPercentage;
  final String historyImage;
  final double? historyLat;
  final double? historyLng;

  History({
    this.historyId,
    required this.historyDisease,
    required this.historyPercentage,
    required this.historyImage,
    this.historyLat,
    this.historyLng,
  });

  bool get hasLocation => historyLat != null && historyLng != null;

  factory History.fromMap(Map<String, dynamic> map) => History(
        historyId: map['ID'] as int?,
        historyDisease: map['Disease'] as String,
        historyPercentage: map['Percentage'] as String,
        historyImage: map['Image'] as String,
        historyLat: (map['Lat'] as num?)?.toDouble(),
        historyLng: (map['Lng'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'Disease': historyDisease,
        'Percentage': historyPercentage,
        'Image': historyImage,
        'Lat': historyLat,
        'Lng': historyLng,
      };
}

// ─── result.dart ──────────────────────────────────────────────────────────────
class Result {
  final String? resultName;
  final String? resultImage;
  double? resultFloat;
  final int? resultIndex;
  String? resultPercentage;

  Result({
    this.resultName,
    this.resultImage,
    this.resultFloat,
    this.resultIndex,
    this.resultPercentage,
  });

  factory Result.fromMap(Map<String, dynamic> map) => Result(
        resultName: map['resultName'] as String?,
        resultImage: map['resultImage'] as String?,
        resultFloat: (map['resultFloat'] as num?)?.toDouble(),
        resultIndex: map['resultIndex'] as int?,
        resultPercentage: map['resultPercentage'] as String?,
      );
}