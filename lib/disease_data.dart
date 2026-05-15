import 'models.dart';

// Static disease reference data used by LibraryScreen and DiseaseScreen.
const List<Map<String, String>> kDiseaseData = [
  {
    'name': 'Bacterial Spot',
    'category': 'Bacterial',
    'crops': 'Tomato, Pepper',
    'symptoms':
        'Small, water-soaked lesions on leaves that turn brown with yellow halos. '
            'Fruit develops raised, scab-like spots. Severely infected leaves drop early.',
    'comments':
        'Spreads rapidly in warm, wet conditions. Infected seed is a primary source.',
    'management':
        'Use certified disease-free seed. Apply copper-based bactericides. '
            'Avoid overhead irrigation. Remove and destroy infected plant debris.',
  },
  {
    'name': 'Early Blight',
    'category': 'Fungal',
    'crops': 'Tomato, Potato',
    'symptoms':
        'Dark brown to black spots with concentric rings (target-board pattern) on older leaves. '
            'Yellowing of tissue surrounding lesions. Stem and fruit can also be affected.',
    'comments':
        'Caused by Alternaria solani. Favoured by warm days and cool, wet nights.',
    'management':
        'Apply fungicides containing chlorothalonil or mancozeb at first sign. '
            'Practise crop rotation. Remove lower infected leaves. Maintain adequate plant spacing.',
  },
  {
    'name': 'Late Blight',
    'category': 'Oomycete',
    'crops': 'Tomato, Potato',
    'symptoms':
        'Pale green to brown, water-soaked lesions on leaves that expand rapidly. '
            'White mould visible on undersides in humid conditions. Tubers develop reddish-brown rot.',
    'comments':
        'Caused by Phytophthora infestans. Destroyed the Irish potato crop in the 1840s. '
            'Can devastate a field within days under cool, moist conditions.',
    'management':
        'Apply protectant fungicides (metalaxyl, chlorothalonil) preventively. '
            'Destroy volunteer potato plants. Store tubers in cool, dry conditions.',
  },
  {
    'name': 'Leaf Mold',
    'category': 'Fungal',
    'crops': 'Tomato',
    'symptoms':
        'Pale greenish-yellow patches on upper leaf surfaces. '
            'Olive-green to brown velvety growth on the underside. Leaves curl and wither.',
    'comments':
        'Caused by Passalora fulva. Common in greenhouses where humidity is high.',
    'management':
        'Improve air circulation. Reduce humidity below 85 %. '
            'Apply fungicides containing chlorothalonil or mancozeb. Use resistant cultivars.',
  },
  {
    'name': 'Powdery Mildew',
    'category': 'Fungal',
    'crops': 'Many crops',
    'symptoms':
        'White to grey powdery patches on upper leaf surfaces and stems. '
            'Affected tissues may yellow and die. Severe infections distort young growth.',
    'comments':
        'Unlike most fungi, thrives in warm, dry conditions. Spores spread by wind.',
    'management':
        'Apply sulphur-based or systemic fungicides (myclobutanil). '
            'Remove infected plant parts. Avoid excess nitrogen fertilisation.',
  },
  {
    'name': 'Rust',
    'category': 'Fungal',
    'crops': 'Many crops',
    'symptoms':
        'Orange, yellow, or brown pustules (uredinia) on leaf undersides. '
            'Upper surface shows yellow flecks. Heavy infection causes defoliation.',
    'comments':
        'Multiple rust species affect different crops. Spreads rapidly via wind-borne spores.',
    'management':
        'Apply fungicides (triazoles, strobilurins) at first sign. '
            'Plant resistant varieties. Remove crop residues after harvest.',
  },
  {
    'name': 'Septoria Leaf Spot',
    'category': 'Fungal',
    'crops': 'Tomato',
    'symptoms':
        'Small circular spots with dark brown borders and light grey centres. '
            'Tiny dark specks (pycnidia) visible in spot centres. Lower leaves affected first.',
    'comments':
        'Caused by Septoria lycopersici. Spreads in cool, wet weather by water splash.',
    'management':
        'Remove and destroy infected leaves. Stake plants for better air flow. '
            'Apply chlorothalonil or mancozeb fungicides. Practise crop rotation.',
  },
  {
    'name': 'Spider Mites',
    'category': 'Pest',
    'crops': 'Many crops',
    'symptoms':
        'Fine stippling or bronzing on leaf surfaces. Webbing on undersides. '
            'Leaves turn yellow, dry out, and drop in severe infestations.',
    'comments':
        'Two-spotted spider mite (Tetranychus urticae) is most common. '
            'Hot, dry conditions accelerate population explosions.',
    'management':
        'Introduce predatory mites (Phytoseiidae). Apply miticides or insecticidal soaps. '
            'Increase humidity. Avoid broad-spectrum insecticides that kill natural enemies.',
  },
  {
    'name': 'Target Spot',
    'category': 'Fungal',
    'crops': 'Tomato',
    'symptoms':
        'Circular brown lesions with concentric rings and yellow halos on leaves. '
            'Dark, sunken lesions on fruit. Stems may show dark streaks.',
    'comments':
        'Caused by Corynespora cassiicola. Associated with high humidity and warm temperatures.',
    'management':
        'Apply fungicides (azoxystrobin, chlorothalonil). '
            'Improve ventilation in greenhouses. Remove plant debris after harvest.',
  },
  {
    'name': 'Yellow Leaf Curl Virus',
    'category': 'Viral',
    'crops': 'Tomato',
    'symptoms':
        'Upward curling and yellowing of young leaves. Stunted plant growth. '
            'Reduced fruit set. Flowers may drop before fruit develops.',
    'comments':
        'Transmitted by silverleaf whitefly (Bemisia tabaci). '
            'No cure once plants are infected.',
    'management':
        'Control whitefly populations with insecticides or reflective mulches. '
            'Use virus-resistant varieties. Remove and destroy infected plants early.',
  },
  {
    'name': 'Mosaic Virus',
    'category': 'Viral',
    'crops': 'Tomato, Many crops',
    'symptoms':
        'Mosaic pattern of light and dark green on leaves. Leaf distortion and stunting. '
            'Reduced fruit size. Fruit may show internal browning.',
    'comments':
        'Tobacco Mosaic Virus (TMV) and Tomato Mosaic Virus (ToMV) are most common. '
            'TMV survives in plant debris for years and spreads by contact.',
    'management':
        'Use resistant varieties. Sanitise tools with 10 % bleach solution. '
            'Control aphid vectors. Remove and destroy infected plants.',
  },
  {
    'name': 'Fusarium Wilt',
    'category': 'Fungal',
    'crops': 'Tomato, Many crops',
    'symptoms':
        'One-sided yellowing of leaves progressing upward. Brown discolouration inside stems. '
            'Wilting even when soil moisture is adequate.',
    'comments':
        'Caused by Fusarium oxysporum. Soil-borne fungus that persists for many years.',
    'management':
        'Plant resistant cultivars. Solarise soil before planting. '
            'Avoid overwatering. Practise long crop rotations (4+ years).',
  },
  {
    'name': 'Verticillium Wilt',
    'category': 'Fungal',
    'crops': 'Tomato, Potato, Many crops',
    'symptoms':
        'V-shaped yellow lesions on leaf margins. Yellowing starts on lower leaves. '
            'Brown vascular discolouration in stems. Plants wilt during hot days.',
    'comments':
        'Caused by Verticillium dahliae. Survives in soil as microsclerotia for 10+ years.',
    'management':
        'Use resistant varieties (V-rated). Soil fumigation or solarisation. '
            'Avoid planting susceptible crops in infested fields.',
  },
  {
    'name': 'Root Rot',
    'category': 'Fungal / Oomycete',
    'crops': 'Many crops',
    'symptoms':
        'Dark brown to black roots that are mushy and foul-smelling. '
            'Wilting, yellowing, and stunted growth. Plants easily pulled from soil.',
    'comments':
        'Caused by several pathogens (Pythium, Phytophthora, Rhizoctonia). '
            'Overwatering and poor drainage are the primary triggers.',
    'management':
        'Improve soil drainage. Avoid overwatering. Apply appropriate fungicides or biocontrol agents. '
            'Use raised beds in poorly drained areas.',
  },
  {
    'name': 'Healthy',
    'category': 'None',
    'crops': 'All',
    'symptoms': 'No disease symptoms present.',
    'comments': 'Plant appears healthy with no signs of infection or pest damage.',
    'management': 'Continue regular monitoring, irrigation, and balanced fertilisation.',
  },
];

Disease? findDisease(String name) {
  final lower = name.toLowerCase();
  for (final d in kDiseaseData) {
    if (d['name']!.toLowerCase() == lower) {
      return Disease(
        diseaseName: d['name'],
        diseaseCategory: d['category'],
        diseaseCrop: d['crops'],
        diseaseSymptoms: d['symptoms'],
        diseaseComments: d['comments'],
        diseaseManagement: d['management'],
      );
    }
  }
  return null;
}
