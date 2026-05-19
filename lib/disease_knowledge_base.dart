import 'diagnostic_report.dart';

/// One complete offline knowledge entry for a single disease / condition.
class KnowledgeEntry {
  final String canonicalName;
  final ConditionType conditionType;
  final SeverityLevel severity;
  final String plantSpecies;
  final String causativeAgent;
  final String biologicalExplanation;
  final List<String> observedSymptoms;
  final List<String> immediateActions;
  final List<String> organicTreatments;
  final List<String> chemicalTreatments;
  final List<String> environmentalCorrections;
  final List<String> preventionSteps;
  final bool isContagious;
  final String? isolationAdvice;

  const KnowledgeEntry({
    required this.canonicalName,
    required this.conditionType,
    required this.severity,
    required this.plantSpecies,
    required this.causativeAgent,
    required this.biologicalExplanation,
    required this.observedSymptoms,
    required this.immediateActions,
    required this.organicTreatments,
    required this.chemicalTreatments,
    required this.environmentalCorrections,
    required this.preventionSteps,
    required this.isContagious,
    this.isolationAdvice,
  });
}

/// Offline knowledge base covering every disease label in the app's model files.
///
/// Lookup is case-insensitive.  Common aliases (e.g. label file variations) are
/// resolved via the [_aliases] map before the main [_db] lookup.
class DiseaseKnowledgeBase {
  DiseaseKnowledgeBase._();

  /// Returns the knowledge entry for [labelName], or null if not found.
  static KnowledgeEntry? getEntry(String labelName) {
    final key = labelName.toLowerCase().trim();
    final resolved = _aliases[key] ?? key;
    return _db[resolved];
  }

  // ── Alias resolution ───────────────────────────────────────────────────────
  // Maps label-file variants → canonical key used in _db.

  static const Map<String, String> _aliases = {
    'tomato yellow leaf curl virus': 'yellow leaf curl virus',
    'tomato mosaic virus': 'mosaic virus',
    'disease detected': 'disease detected',
  };

  // ── Knowledge database ────────────────────────────────────────────────────

  static final Map<String, KnowledgeEntry> _db = {

    // ── Bacterial Spot ────────────────────────────────────────────────────────
    'bacterial spot': const KnowledgeEntry(
      canonicalName: 'Bacterial Spot',
      conditionType: ConditionType.bacterial,
      severity: SeverityLevel.high,
      plantSpecies: 'Tomato, Pepper',
      causativeAgent: 'Xanthomonas campestris / X. vesicatoria',
      biologicalExplanation:
          'Xanthomonas bacteria enter leaf tissue through stomata and natural '
          'openings, producing enzymes that break down cell walls. Warm (24–30 °C) '
          'wet weather and overhead irrigation dramatically accelerate spread, as '
          'water splash disperses bacteria across the canopy.',
      observedSymptoms: [
        'Small, water-soaked spots on leaves, stems, and fruit',
        'Spots enlarge and turn dark brown to black with distinctive yellow halos',
        'Lesions may merge, forming large irregular necrotic patches',
        'Raised, scab-like lesions on fruit surface',
        'Premature leaf drop in severe infections',
        'Dark, water-soaked streaks on young stems',
      ],
      immediateActions: [
        'Remove and destroy all visibly infected leaves immediately',
        'Switch immediately to drip or surface irrigation — stop all overhead watering',
        'Disinfect pruning tools with 10 % bleach solution between cuts',
        'Apply copper-based bactericide spray within 24 hours',
        'Improve canopy airflow by removing dense inner foliage',
      ],
      organicTreatments: [
        'Copper hydroxide or copper sulfate spray (repeat every 7–10 days)',
        'Neem oil solution (diluted 2 %) applied in the evening',
        'Bacillus subtilis biological spray (Serenade or equivalent)',
        'Hydrogen peroxide foliar spray (diluted 0.5 %) for surface disinfection',
      ],
      chemicalTreatments: [
        'Copper oxychloride fungicide-bactericide',
        'Streptomycin antibiotic spray (where legally permitted)',
        'Mancozeb + copper combination product',
        'Kasugamycin bactericide for severe outbreaks',
      ],
      environmentalCorrections: [
        'Reduce humidity around foliage — ensure adequate plant spacing',
        'Avoid working with plants when foliage is wet',
        'Avoid excessive nitrogen fertilisation that promotes soft, susceptible tissue',
      ],
      preventionSteps: [
        'Use only certified disease-free or resistant seed varieties',
        'Practice 2–3 year crop rotation — do not follow tomato or pepper',
        'Apply preventive copper sprays before the rainy season',
        'Mulch the soil surface to minimise rain-splash dispersal',
        'Sanitise all tools and equipment between uses',
      ],
      isContagious: true,
      isolationAdvice:
          'Highly contagious via rain splash, wind-blown water, and direct contact. '
          'Isolate affected plants and handle healthy plants first.',
    ),

    // ── Early Blight ──────────────────────────────────────────────────────────
    'early blight': const KnowledgeEntry(
      canonicalName: 'Early Blight',
      conditionType: ConditionType.fungal,
      severity: SeverityLevel.medium,
      plantSpecies: 'Tomato, Potato',
      causativeAgent: 'Alternaria solani',
      biologicalExplanation:
          'Alternaria solani produces spores that germinate on leaf surfaces in '
          'warm (24–29 °C), humid conditions. The fungus penetrates through '
          'stomata and wounds, causing characteristic target-board lesions. '
          'It progresses from older, lower leaves upward, weakening the plant '
          'over weeks.',
      observedSymptoms: [
        'Dark brown circular spots with distinctive concentric rings (bull\'s-eye)',
        'Yellow halo surrounding each lesion',
        'Lesions start on oldest (lower) leaves, progressing upward',
        'Affected leaves turn yellow and drop prematurely',
        'Dark, sunken cankers possible at stem base (collar rot)',
        'Fruit shows dark leathery lesions near the stem end',
      ],
      immediateActions: [
        'Remove and discard all infected lower leaves — do not compost',
        'Apply fungicide immediately at first sign of bull\'s-eye spots',
        'Stake plants to keep foliage off the ground',
        'Mulch soil surface to prevent spore splash from soil',
      ],
      organicTreatments: [
        'Copper-based fungicide spray (copper hydroxide)',
        'Neem oil spray every 7 days during wet weather',
        'Bicarbonate spray (1 tbsp baking soda + 1 tsp horticultural oil per litre)',
        'Trichoderma-based biocontrol applied to soil and foliage',
      ],
      chemicalTreatments: [
        'Chlorothalonil (Daconil) — protectant fungicide',
        'Mancozeb-based fungicide',
        'Azoxystrobin (systemic, good for prevention)',
        'Difenoconazole for curative action',
      ],
      environmentalCorrections: [
        'Avoid wetting foliage during irrigation',
        'Ensure adequate spacing (60+ cm) for good air circulation',
        'Apply balanced fertiliser — low potassium weakens resistance',
      ],
      preventionSteps: [
        'Rotate crops — do not replant tomato or potato for 2–3 years',
        'Choose resistant varieties where available',
        'Apply preventive fungicide spray during warm, wet spells',
        'Remove and destroy all crop residues after harvest',
        'Use certified pathogen-free transplants',
      ],
      isContagious: true,
      isolationAdvice:
          'Spreads via wind-blown spores and water splash. '
          'Keep infected plants away from healthy ones and avoid overhead watering.',
    ),

    // ── Late Blight ───────────────────────────────────────────────────────────
    'late blight': const KnowledgeEntry(
      canonicalName: 'Late Blight',
      conditionType: ConditionType.oomycete,
      severity: SeverityLevel.critical,
      plantSpecies: 'Tomato, Potato',
      causativeAgent: 'Phytophthora infestans',
      biologicalExplanation:
          'Phytophthora infestans is a water mould (oomycete), not a true fungus. '
          'It thrives in cool (10–20 °C), wet conditions and can destroy an '
          'entire field within days. Sporangia released from leaf lesions travel '
          'by wind and rain to infect new tissue within hours. The same pathogen '
          'caused the Irish Potato Famine of the 1840s.',
      observedSymptoms: [
        'Irregular, pale green to brown water-soaked lesions on leaves',
        'Lesions rapidly expand, turning dark brown to black',
        'White, fuzzy sporulation visible on leaf undersides in humid conditions',
        'Infected stems show dark brown cankers — plants may collapse',
        'Fruit develops hard, brown, irregular lesions',
        'Entire plant can collapse within 3–5 days of severe infection',
      ],
      immediateActions: [
        'Act immediately — late blight can destroy a crop within days',
        'Remove and bag (do not compost) all severely infected plants',
        'Apply systemic fungicide (metalaxyl-based) without delay',
        'Notify neighbouring growers — airborne spores spread rapidly',
        'Increase plant spacing if possible and remove lower infected leaves',
      ],
      organicTreatments: [
        'Copper hydroxide spray applied preventively every 5–7 days',
        'Bordeaux mixture (copper sulfate + lime) — traditional preventive',
        'Phosphonate-based biostimulants to boost plant resistance',
      ],
      chemicalTreatments: [
        'Metalaxyl-M (Ridomil) — systemic, penetrates infected tissue',
        'Cymoxanil + mancozeb combination for curative action',
        'Chlorothalonil for protective coverage',
        'Dimethomorph for resistance management (rotate chemistries)',
      ],
      environmentalCorrections: [
        'Avoid overhead irrigation entirely during susceptible periods',
        'Improve drainage — waterlogged soil accelerates root infection',
        'Do not plant in low-lying, frost-prone areas prone to morning fog',
      ],
      preventionSteps: [
        'Plant certified disease-free seed potatoes and resistant tomato varieties',
        'Monitor weather forecasts — apply fungicides before predicted rain',
        'Destroy all volunteer potato plants (reservoir of inoculum)',
        'Harvest potato tubers during dry weather and store in cool, dry conditions',
        'Practice strict 3-year rotation — pathogen persists in infected tubers',
      ],
      isContagious: true,
      isolationAdvice:
          'Extremely contagious — wind-borne spores travel kilometres. '
          'Remove and bag infected plant material immediately. Do NOT leave it in the field.',
    ),

    // ── Leaf Mold ─────────────────────────────────────────────────────────────
    'leaf mold': const KnowledgeEntry(
      canonicalName: 'Leaf Mold',
      conditionType: ConditionType.fungal,
      severity: SeverityLevel.medium,
      plantSpecies: 'Tomato',
      causativeAgent: 'Passalora fulva (syn. Cladosporium fulvum)',
      biologicalExplanation:
          'Passalora fulva is an obligate biotrophic fungus that lives only on '
          'living tomato tissue. It thrives at humidity above 85 % and temperatures '
          'of 22–25 °C — typical greenhouse conditions. Conidia produced on the '
          'leaf underside are wind-dispersed to healthy leaves.',
      observedSymptoms: [
        'Pale yellow-green patches on the upper leaf surface',
        'Olive-green to brown velvety mould growth on the leaf underside',
        'Leaf edges may curl upward; severely infected leaves wither and drop',
        'Early infections appear as irregular pale spots before mould develops',
        'Lower canopy leaves are typically affected first',
      ],
      immediateActions: [
        'Improve greenhouse ventilation immediately — open vents, add fans',
        'Reduce humidity below 85 % by improving airflow',
        'Remove and destroy severely infected leaves',
        'Apply fungicide spray to all foliage, including leaf undersides',
      ],
      organicTreatments: [
        'Potassium bicarbonate spray (effective against many leaf moulds)',
        'Neem oil foliar spray every 7 days',
        'Copper-based fungicide applied to leaf undersides',
        'Trichoderma harzianum biocontrol spray',
      ],
      chemicalTreatments: [
        'Chlorothalonil fungicide',
        'Mancozeb spray',
        'Cymoxanil-based product for systemic action',
        'Difenoconazole for resistant strains',
      ],
      environmentalCorrections: [
        'Maintain humidity below 85 % — install ventilation or dehumidifiers',
        'Increase plant spacing to allow air movement between plants',
        'Water early in the day so foliage dries before nightfall',
        'Avoid working among plants when foliage is wet',
      ],
      preventionSteps: [
        'Choose Cf-resistant tomato varieties (Cf genes confer resistance)',
        'Maintain good greenhouse hygiene — sanitise structures between crops',
        'Monitor humidity continuously with a hygrometer',
        'Remove crop debris thoroughly after each crop cycle',
      ],
      isContagious: true,
      isolationAdvice:
          'Spreads readily in enclosed spaces via wind-borne conidia. '
          'Improve ventilation and treat all plants in the greenhouse simultaneously.',
    ),

    // ── Powdery Mildew ────────────────────────────────────────────────────────
    'powdery mildew': const KnowledgeEntry(
      canonicalName: 'Powdery Mildew',
      conditionType: ConditionType.fungal,
      severity: SeverityLevel.medium,
      plantSpecies: 'Many crops (tomato, squash, cucumber, beans)',
      causativeAgent: 'Various Erysiphales species',
      biologicalExplanation:
          'Unlike most fungal diseases, powdery mildew thrives in warm (20–28 °C), '
          'DRY conditions with low humidity. The surface mycelium does not penetrate '
          'deep into tissue, making early treatment highly effective. Spores '
          'spread rapidly by wind.',
      observedSymptoms: [
        'White to grey powdery coating on upper leaf surfaces',
        'Powdery patches may also appear on stems and young fruit',
        'Affected tissue yellows and dies as infection advances',
        'Young growth is most susceptible — distorted or stunted leaves',
        'Severe infections cause premature leaf drop and fruit quality loss',
      ],
      immediateActions: [
        'Remove and destroy heavily infected leaves',
        'Apply fungicide or organic treatment immediately — mildew responds well to early treatment',
        'Improve air circulation around plants',
        'Avoid excess nitrogen fertiliser which promotes susceptible soft growth',
      ],
      organicTreatments: [
        'Potassium bicarbonate spray (highly effective — changes leaf pH)',
        'Diluted milk spray (40 % milk / 60 % water) — field-proven',
        'Neem oil spray every 7 days',
        'Wettable sulphur spray (do not apply in temperatures above 30 °C)',
      ],
      chemicalTreatments: [
        'Myclobutanil (systemic triazole fungicide)',
        'Tebuconazole',
        'Azoxystrobin (strobilurin)',
        'Sulphur-based fungicide for field crops',
      ],
      environmentalCorrections: [
        'Ensure adequate plant spacing for air movement',
        'Avoid excessive nitrogen — balance with phosphorus and potassium',
        'Do not over-irrigate — mild water stress reduces susceptibility',
      ],
      preventionSteps: [
        'Choose mildew-resistant varieties where available',
        'Practice crop rotation and clean up debris after harvest',
        'Apply preventive sprays during hot, dry conditions',
        'Monitor plants weekly for early white spots',
      ],
      isContagious: true,
      isolationAdvice: null,
    ),

    // ── Rust ──────────────────────────────────────────────────────────────────
    'rust': const KnowledgeEntry(
      canonicalName: 'Rust',
      conditionType: ConditionType.fungal,
      severity: SeverityLevel.high,
      plantSpecies: 'Many crops (beans, maize, wheat, soybean)',
      causativeAgent: 'Various Puccinia / Uromyces species',
      biologicalExplanation:
          'Rust fungi are obligate parasites with complex life cycles, sometimes '
          'requiring two different host plant species. Urediniospores (the main '
          'spreading stage) are produced in large quantities and dispersed '
          'long distances by wind. Infection is favoured by leaf wetness and '
          'temperatures of 15–25 °C.',
      observedSymptoms: [
        'Orange, yellow, or reddish-brown powdery pustules on leaf undersides',
        'Corresponding yellow flecks or pale spots on the upper leaf surface',
        'Pustules rupture to release masses of dusty spores',
        'Heavy infection causes rapid leaf yellowing and defoliation',
        'Severely infected plants show premature death and yield loss',
      ],
      immediateActions: [
        'Apply fungicide immediately at first sign of pustules',
        'Remove and bag severely infected leaves (do not compost)',
        'Avoid working in the field when foliage is wet to reduce spread',
      ],
      organicTreatments: [
        'Sulphur dust or wettable sulphur spray (not above 30 °C)',
        'Neem oil spray applied to both leaf surfaces',
        'Copper-based fungicide for mild infections',
      ],
      chemicalTreatments: [
        'Triazole fungicides (tebuconazole, propiconazole)',
        'Strobilurin fungicides (azoxystrobin, pyraclostrobin)',
        'Combination products (strobilurin + triazole) for resistant strains',
      ],
      environmentalCorrections: [
        'Improve airflow between plants',
        'Avoid overhead irrigation — wet foliage promotes infection',
      ],
      preventionSteps: [
        'Plant rust-resistant varieties',
        'Apply protective fungicide sprays before humid, cool periods',
        'Remove crop debris after harvest — reduces inoculum load',
        'Monitor field edges where alternate hosts may harbour rust',
      ],
      isContagious: true,
      isolationAdvice:
          'Wind-borne spores travel long distances. Treat surrounding plants '
          'preventively when rust is detected in any part of the field.',
    ),

    // ── Septoria Leaf Spot ────────────────────────────────────────────────────
    'septoria leaf spot': const KnowledgeEntry(
      canonicalName: 'Septoria Leaf Spot',
      conditionType: ConditionType.fungal,
      severity: SeverityLevel.medium,
      plantSpecies: 'Tomato',
      causativeAgent: 'Septoria lycopersici',
      biologicalExplanation:
          'Septoria lycopersici survives in infected crop debris and soil. '
          'Conidia are water-splashed to lower leaves and germinate in cool '
          '(15–22 °C), wet conditions. The fungus kills leaf tissue by producing '
          'toxins, leading to progressive leaf loss from the bottom of the plant upward.',
      observedSymptoms: [
        'Numerous small (3–5 mm) circular spots with dark brown margins',
        'Spot centres are grey to tan with tiny dark specks (pycnidia)',
        'Lower, older leaves are affected first — progresses upward',
        'Heavy spotting causes leaf yellowing and drop',
        'Defoliated plants are exposed to sunscald on fruit',
      ],
      immediateActions: [
        'Remove all lower infected leaves and destroy them',
        'Apply fungicide spray starting from lower canopy',
        'Stake or support plants to lift foliage off the ground',
        'Mulch the soil surface to prevent spore splash',
      ],
      organicTreatments: [
        'Copper-based fungicide spray (copper hydroxide)',
        'Neem oil spray every 7 days',
        'Potassium bicarbonate solution',
      ],
      chemicalTreatments: [
        'Chlorothalonil — protectant, very effective against Septoria',
        'Mancozeb spray',
        'Azoxystrobin (systemic)',
        'Difenoconazole for curative action',
      ],
      environmentalCorrections: [
        'Avoid overhead irrigation — water at the base only',
        'Ensure good plant spacing for airflow',
        'Keep weeds under control — some are alternative hosts',
      ],
      preventionSteps: [
        'Rotate crops — avoid tomato in the same plot for 2 years',
        'Use disease-resistant varieties',
        'Remove and destroy all plant residues after harvest',
        'Apply preventive copper sprays during cool, wet weather',
      ],
      isContagious: true,
      isolationAdvice: null,
    ),

    // ── Spider Mites ──────────────────────────────────────────────────────────
    'spider mites': const KnowledgeEntry(
      canonicalName: 'Spider Mites',
      conditionType: ConditionType.pest,
      severity: SeverityLevel.medium,
      plantSpecies: 'Many crops',
      causativeAgent: 'Tetranychus urticae (two-spotted spider mite)',
      biologicalExplanation:
          'Spider mites pierce individual leaf cells and extract contents, '
          'causing the characteristic stippled "sandpaper" texture. They '
          'reproduce extremely rapidly (generation time ~1 week at 30 °C) '
          'and thrive in hot, dry conditions. A single female can produce '
          'over 100 eggs. Fine webbing serves as protection and a dispersal aid.',
      observedSymptoms: [
        'Fine stippling or bronzing on leaf surfaces (thousands of tiny puncture marks)',
        'Thin webbing on leaf undersides and between leaves',
        'Leaves turn yellow, bronze, then brown and dry',
        'Premature leaf drop in severe infestations',
        'Tiny moving dots visible with magnification on leaf undersides',
        'Plant growth stunted, fruit quality reduced',
      ],
      immediateActions: [
        'Spray plants forcefully with water — knocks mites off leaves',
        'Increase humidity around plants — spider mites hate moisture',
        'Apply miticide or insecticidal soap immediately',
        'Remove and destroy heavily infested leaves',
      ],
      organicTreatments: [
        'Neem oil spray (effective as miticide)',
        'Insecticidal soap spray (potassium fatty acids)',
        'Introduce predatory mites: Phytoseiulus persimilis or Neoseiulus californicus',
        'Diatomaceous earth applied to soil and lower stems',
        'Strong water spray to physically dislodge mites (repeat daily)',
      ],
      chemicalTreatments: [
        'Abamectin (miticide — rotational use)',
        'Bifenazate (contact miticide)',
        'Spiromesifen (ovicidal + adulticide)',
        'Hexythiazox (mainly ovicidal — use with adulticide)',
      ],
      environmentalCorrections: [
        'Increase irrigation frequency — drought stress worsens infestations',
        'Raise humidity with misting systems in greenhouses',
        'Reduce dust on leaf surfaces — dust protects mites from predators',
      ],
      preventionSteps: [
        'Monitor plants weekly with a magnifying glass, especially undersides of leaves',
        'Avoid broad-spectrum insecticides that kill natural predators',
        'Introduce predatory mites proactively in greenhouse crops',
        'Manage weeds that serve as mite reservoirs around the growing area',
      ],
      isContagious: false,
      isolationAdvice:
          'Mites disperse by wind and on clothing. Handle infested plants last '
          'and change clothing before working with unaffected crops.',
    ),

    // ── Target Spot ───────────────────────────────────────────────────────────
    'target spot': const KnowledgeEntry(
      canonicalName: 'Target Spot',
      conditionType: ConditionType.fungal,
      severity: SeverityLevel.medium,
      plantSpecies: 'Tomato, Cucumber, Pepper',
      causativeAgent: 'Corynespora cassiicola',
      biologicalExplanation:
          'Corynespora cassiicola is a wide host-range fungus that produces '
          'conidia on leaf lesions. These are dispersed by wind and water splash. '
          'Infection is promoted by warm (25–30 °C) temperatures and high relative '
          'humidity (>80 %). The distinctive concentric ring pattern is caused by '
          'alternating rings of dead and living tissue.',
      observedSymptoms: [
        'Circular brown lesions with concentric rings — similar to a target or bull\'s-eye',
        'Lesions have yellow halos on leaves',
        'Dark, sunken circular lesions on fruit',
        'Stem lesions appear as dark elongated streaks',
        'Severely infected leaves yellow and drop',
      ],
      immediateActions: [
        'Remove and destroy infected plant material',
        'Apply fungicide spray immediately',
        'Reduce humidity — improve ventilation in greenhouses',
        'Switch to drip irrigation to reduce leaf wetness',
      ],
      organicTreatments: [
        'Copper hydroxide spray',
        'Neem oil solution applied every 7 days',
        'Bacillus subtilis biocontrol spray',
      ],
      chemicalTreatments: [
        'Azoxystrobin (strobilurin — systemic)',
        'Chlorothalonil (protectant)',
        'Fludioxonil + cyprodinil combination',
        'Difenoconazole for curative action',
      ],
      environmentalCorrections: [
        'Maintain humidity below 80 %',
        'Ensure good airflow around plants',
        'Avoid watering in the evening',
      ],
      preventionSteps: [
        'Practice crop rotation',
        'Use disease-tolerant varieties',
        'Apply preventive fungicide before humid periods',
        'Remove crop debris thoroughly after harvest',
      ],
      isContagious: true,
      isolationAdvice: null,
    ),

    // ── Yellow Leaf Curl Virus ─────────────────────────────────────────────────
    'yellow leaf curl virus': const KnowledgeEntry(
      canonicalName: 'Yellow Leaf Curl Virus',
      conditionType: ConditionType.viral,
      severity: SeverityLevel.high,
      plantSpecies: 'Tomato, Pepper, Bean',
      causativeAgent: 'Tomato Yellow Leaf Curl Virus (TYLCV) — transmitted by Bemisia tabaci whitefly',
      biologicalExplanation:
          'TYLCV is a geminivirus transmitted persistently by the silverleaf '
          'whitefly (Bemisia tabaci). Once a plant is infected there is no cure '
          '— the virus replicates throughout plant tissue, disrupting growth '
          'hormones and causing the characteristic leaf curling and stunting. '
          'Viral particles persist in the whitefly vector for its lifetime.',
      observedSymptoms: [
        'Upward and inward curling of young leaves (cupping)',
        'Yellowing (chlorosis) of leaf margins and interveinal areas',
        'Severe stunting of plant growth',
        'Greatly reduced fruit set — flowers drop before fruit develops',
        'Thickened, leathery leaf texture',
        'Small, misshapen fruits in surviving plants',
      ],
      immediateActions: [
        'Remove and destroy all infected plants immediately to limit virus spread',
        'Apply insecticide targeting whiteflies (the virus vector)',
        'Install reflective silver/aluminium mulch to repel whiteflies',
        'Apply sticky yellow traps to monitor and reduce whitefly numbers',
      ],
      organicTreatments: [
        'Insecticidal soap spray targeting whitefly nymphs on leaf undersides',
        'Neem oil spray (disrupts whitefly lifecycle)',
        'Reflective silver mulch on soil surface to confuse and deter whiteflies',
        'Introduce Encarsia formosa (parasitic wasp) in greenhouse settings',
      ],
      chemicalTreatments: [
        'Imidacloprid soil drench (systemic, absorbed by plant — kills feeding whiteflies)',
        'Spirotetramat (targets whitefly nymphs)',
        'Pyrethroids as knockdown sprays (rotate to avoid resistance)',
        'Acetamiprid for adult whitefly control',
      ],
      environmentalCorrections: [
        'Establish insect-proof screens on greenhouse openings',
        'Use reflective mulches to reduce whitefly landing on plants',
        'Avoid growing tomatoes near crops that host whiteflies',
      ],
      preventionSteps: [
        'Plant TYLCV-resistant or tolerant tomato varieties',
        'Use certified virus-free transplants only',
        'Establish a 200 m buffer from previous season\'s infected fields',
        'Inspect transplants thoroughly for whiteflies before planting',
        'Remove and destroy crop residues immediately after harvest',
      ],
      isContagious: true,
      isolationAdvice:
          'The virus spreads via whitefly vectors — isolate infected plants and '
          'treat surrounding plants with insecticides to reduce vector pressure. '
          'Infected plants cannot recover and should be removed.',
    ),

    // ── Mosaic Virus ──────────────────────────────────────────────────────────
    'mosaic virus': const KnowledgeEntry(
      canonicalName: 'Mosaic Virus',
      conditionType: ConditionType.viral,
      severity: SeverityLevel.high,
      plantSpecies: 'Tomato, Cucumber, Pepper, Squash',
      causativeAgent: 'Tomato Mosaic Virus (ToMV) / Tobacco Mosaic Virus (TMV)',
      biologicalExplanation:
          'TMV and ToMV are among the most stable plant viruses known, surviving '
          'in dried plant tissue for decades. They spread primarily through '
          'contact — from contaminated hands, tools, clothing, or infected seed. '
          'There is no chemical cure once infection occurs.',
      observedSymptoms: [
        'Irregular mosaic pattern of light and dark green areas on leaves',
        'Leaf distortion, wrinkling, and curling',
        'Stunted overall plant growth',
        'Reduced fruit size and yield',
        'Fruit may show internal browning or necrotic streaks',
        'Fern-leaf symptom (narrow, distorted leaflets) in some strains',
      ],
      immediateActions: [
        'Remove and bag infected plants — do not compost',
        'Wash hands thoroughly with soap after handling infected plants',
        'Disinfect all tools with 10 % bleach or 70 % isopropyl alcohol',
        'Change clothing after contact with infected material',
      ],
      organicTreatments: [
        'No curative organic treatment exists — focus on prevention and removal',
        'Neem oil sprays to control aphid vectors',
        'Reflective mulches to deter aphid vectors',
      ],
      chemicalTreatments: [
        'No viricide is available — chemical management targets aphid vectors only',
        'Imidacloprid for systemic aphid control',
        'Pyrethroids for contact aphid knockdown',
      ],
      environmentalCorrections: [
        'Reduce physical contact between plants during management operations',
        'Wash hands before and after plant handling sessions',
      ],
      preventionSteps: [
        'Use TMV/ToMV-resistant varieties (Tm-2 gene)',
        'Use certified virus-free seed only',
        'Disinfect all tools and equipment before use',
        'Do not handle plants after using tobacco products (TMV reservoir)',
        'Control aphid populations which spread many viral strains',
      ],
      isContagious: true,
      isolationAdvice:
          'TMV survives on hands, tools, and clothing for extended periods. '
          'Strict contact hygiene is essential. Infected plants are a permanent '
          'source and should be removed from the field.',
    ),

    // ── Fusarium Wilt ─────────────────────────────────────────────────────────
    'fusarium wilt': const KnowledgeEntry(
      canonicalName: 'Fusarium Wilt',
      conditionType: ConditionType.fungal,
      severity: SeverityLevel.critical,
      plantSpecies: 'Tomato, Banana, Melon, Cucumber',
      causativeAgent: 'Fusarium oxysporum f.sp. lycopersici',
      biologicalExplanation:
          'Fusarium oxysporum invades roots and colonises the vascular system '
          '(xylem), blocking water and nutrient transport. It produces toxins '
          'that accelerate wilting. The fungus forms chlamydospores that persist '
          'in soil for 10+ years even without a host plant. Warm (25–28 °C) '
          'soil and acidic pH favour the disease.',
      observedSymptoms: [
        'Wilting on one or two branches while the rest of the plant appears normal',
        'Yellowing of lower leaves, progressing asymmetrically upward',
        'Brown to dark brown discolouration of vascular tissue (visible in stem cross-section)',
        'Plants wilt in the afternoon but partially recover overnight initially',
        'Eventually permanent wilting and plant death',
        'Roots may show brown to black discolouration',
      ],
      immediateActions: [
        'Remove and destroy infected plants immediately — do not compost',
        'Do not replant susceptible crops in the same soil',
        'Solarise the soil: cover with clear plastic for 4–6 weeks in summer',
        'Adjust soil pH to 6.5–7.0 (less favourable for pathogen)',
      ],
      organicTreatments: [
        'Trichoderma viride/harzianum soil drench (biocontrol)',
        'Bacillus subtilis soil application',
        'Compost-enriched soil (microbial competition reduces pathogen)',
        'Mycorrhizal inoculants to improve root health and competition',
      ],
      chemicalTreatments: [
        'Metalaxyl soil drench (preventive)',
        'Thiophanate-methyl (limited systemic activity)',
        'Carbendazim soil drench',
        'Note: chemical control is limited — resistant varieties are more effective',
      ],
      environmentalCorrections: [
        'Improve soil drainage — waterlogged conditions worsen disease',
        'Avoid overwatering — maintain consistent moisture',
        'Solarise or steam-sterilise soil before replanting',
      ],
      preventionSteps: [
        'Plant Fusarium-resistant varieties (F/FF/FFF rated)',
        'Rotate with non-solanaceous crops for 4+ years',
        'Use raised beds and ensure excellent drainage',
        'Apply biocontrol agents at transplanting time',
        'Do not move infected soil to clean areas on equipment',
      ],
      isContagious: true,
      isolationAdvice:
          'Soil-borne pathogen persists for years. Contaminated soil, tools, '
          'water runoff, and transplants can spread the fungus to new areas.',
    ),

    // ── Verticillium Wilt ─────────────────────────────────────────────────────
    'verticillium wilt': const KnowledgeEntry(
      canonicalName: 'Verticillium Wilt',
      conditionType: ConditionType.fungal,
      severity: SeverityLevel.high,
      plantSpecies: 'Tomato, Potato, Strawberry, Pepper',
      causativeAgent: 'Verticillium dahliae / V. albo-atrum',
      biologicalExplanation:
          'Verticillium dahliae forms melanised microsclerotia in soil that '
          'persist for 10+ years. Root infection occurs in cool (20–25 °C) '
          'soil, and the fungus colonises the vascular system. Unlike Fusarium, '
          'symptoms typically appear in cool-to-warm conditions, and wilt is '
          'often reversible overnight in early stages.',
      observedSymptoms: [
        'V-shaped yellow lesions starting from leaf margins, progressing inward',
        'Yellowing starts on lower leaves and progresses upward',
        'Brown vascular discolouration in lower stem (less intense than Fusarium)',
        'Plants wilt during hot midday temperatures, partially recovering at night',
        'Gradual decline rather than rapid collapse',
        'One side of the plant often more affected than the other',
      ],
      immediateActions: [
        'Remove and destroy infected plants',
        'Avoid replanting susceptible crops in the same area',
        'Solarise soil during hot weather to reduce inoculum',
      ],
      organicTreatments: [
        'Trichoderma soil application as biocontrol',
        'Organic matter incorporation to stimulate suppressive microbiome',
        'Mycorrhizal root inoculants',
      ],
      chemicalTreatments: [
        'Soil fumigants (metam sodium) for pre-plant treatment',
        'Thiophanate-methyl drench (limited efficacy)',
        'Note: no fully effective chemical cure — use resistant varieties',
      ],
      environmentalCorrections: [
        'Ensure good drainage',
        'Avoid planting in previously infested fields',
        'Amend soil with mature compost to build biological suppression',
      ],
      preventionSteps: [
        'Use V-rated resistant varieties (V code on seed packets)',
        'Rotate with non-host crops (grasses, corn) for 4+ years',
        'Soil solarisation before planting',
        'Avoid equipment movement between clean and infested fields',
      ],
      isContagious: true,
      isolationAdvice:
          'Soil-borne. Infected plant residues, water runoff, and contaminated '
          'tools can spread microsclerotia to clean fields.',
    ),

    // ── Root Rot ──────────────────────────────────────────────────────────────
    'root rot': const KnowledgeEntry(
      canonicalName: 'Root Rot',
      conditionType: ConditionType.fungal,
      severity: SeverityLevel.critical,
      plantSpecies: 'Most crops',
      causativeAgent: 'Pythium spp., Phytophthora spp., Rhizoctonia solani',
      biologicalExplanation:
          'Root rot is caused by several pathogens that thrive in waterlogged, '
          'poorly-drained soils. Pythium and Phytophthora are water moulds that '
          'produce mobile zoospores that swim to roots. Rhizoctonia infects under '
          'cool, wet conditions. All cause rapid decomposition of root tissue, '
          'shutting down water and nutrient uptake.',
      observedSymptoms: [
        'Wilting despite adequate soil moisture',
        'Yellowing and browning of lower leaves',
        'Stunted growth and poor vigour',
        'Roots are dark brown to black, mushy, and may smell foul',
        'Plants easily pulled from soil with minimal root resistance',
        'Crown tissue at soil level may show dark rot',
      ],
      immediateActions: [
        'Stop watering immediately — allow soil to partially dry',
        'If in containers, check drainage holes — clear blockages',
        'Remove plant from soil, trim black/soft roots, allow to dry briefly',
        'Repot in well-draining mix or improve field drainage urgently',
        'Apply Trichoderma or phosphonate drench to remaining roots',
      ],
      organicTreatments: [
        'Trichoderma harzianum soil drench (biocontrol)',
        'Cinnamon powder on cut root ends (natural antifungal)',
        'Chamomile tea drench for mild Pythium (folk remedy)',
        'Beneficial bacteria (Bacillus subtilis) drench',
      ],
      chemicalTreatments: [
        'Metalaxyl-M soil drench (effective against Pythium and Phytophthora)',
        'Fosetyl-aluminium (phosphonate, systemic)',
        'Mefenoxam drench',
        'Iprodione or flutolanil for Rhizoctonia',
      ],
      environmentalCorrections: [
        'Dramatically improve soil drainage — add grit, sand, or perlite',
        'Use raised beds to elevate roots above waterlogged zone',
        'Reduce irrigation frequency — allow soil to partially dry between waterings',
        'Avoid compacting soil around the root zone',
      ],
      preventionSteps: [
        'Ensure excellent drainage before planting',
        'Do not overwater — use soil moisture sensors or finger test',
        'Use well-draining potting mix in containers',
        'Solarise or sterilise growing media between crops',
        'Avoid planting in the same waterlogged area repeatedly',
      ],
      isContagious: true,
      isolationAdvice:
          'Spreads through infected soil, water, and contaminated tools. '
          'Isolate severely infected plants and sanitise tools.',
    ),

    // ── Generic disease detected (single-class YOLO model) ────────────────────
    'disease detected': const KnowledgeEntry(
      canonicalName: 'Disease Detected',
      conditionType: ConditionType.unknown,
      severity: SeverityLevel.medium,
      plantSpecies: 'Unknown',
      causativeAgent: 'Unknown — further diagnosis needed',
      biologicalExplanation:
          'The on-device model detected visual abnormalities consistent with '
          'plant disease, but could not identify the specific condition from '
          'this image. A closer, higher-quality photo of the affected leaf area '
          'is needed for precise identification.',
      observedSymptoms: [
        'Visual abnormalities were detected in the leaf image',
        'Specific symptom identification requires a clearer photo',
        'Affected area should be photographed up close under natural light',
      ],
      immediateActions: [
        'Photograph the affected leaf up close in natural daylight',
        'Compare symptoms with a crop disease reference guide',
        'Consult a local agricultural extension officer if symptoms are severe',
        'Monitor surrounding plants for similar symptoms',
      ],
      organicTreatments: [
        'Apply broad-spectrum preventive copper spray as a precaution',
        'Ensure good plant nutrition and avoid water stress',
      ],
      chemicalTreatments: [
        'Await specific diagnosis before applying targeted treatments',
      ],
      environmentalCorrections: [
        'Improve plant growing conditions generally',
        'Ensure adequate irrigation, nutrition, and airflow',
      ],
      preventionSteps: [
        'Monitor plants weekly for early signs of disease',
        'Maintain good field hygiene and crop rotation',
      ],
      isContagious: false,
      isolationAdvice: null,
    ),

    // ── Healthy ───────────────────────────────────────────────────────────────
    'healthy': const KnowledgeEntry(
      canonicalName: 'Healthy',
      conditionType: ConditionType.healthy,
      severity: SeverityLevel.none,
      plantSpecies: 'Any',
      causativeAgent: 'None',
      biologicalExplanation:
          'The plant shows no visual signs of disease, pest damage, or stress. '
          'Normal leaf colour, texture, and structure are present.',
      observedSymptoms: [
        'Normal leaf colour — vibrant green appropriate for the crop',
        'No spots, lesions, or discolouration detected',
        'Leaf structure and texture appear normal',
      ],
      immediateActions: [
        'Continue regular monitoring',
        'Maintain current growing conditions',
      ],
      organicTreatments: [],
      chemicalTreatments: [],
      environmentalCorrections: [
        'Ensure consistent irrigation and balanced fertilisation',
        'Monitor weekly for early signs of stress',
      ],
      preventionSteps: [
        'Continue preventive practices: crop rotation, good sanitation',
        'Apply preventive foliar sprays if disease pressure is expected',
        'Monitor soil health and plant nutrition regularly',
      ],
      isContagious: false,
      isolationAdvice: null,
    ),
  };
}
