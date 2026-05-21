import 'package:flutter/material.dart';

// ─── Plantation ───────────────────────────────────────────────────────────────

class PlantationData {
  final String farmerName;
  final String plotName;
  final String healthStatus;
  final double airTemp;
  final double soilHumidity;
  final double soilNutrients;
  final String weather;
  final double tempMax;
  final double tempMin;
  final String city;

  const PlantationData({
    required this.farmerName,
    required this.plotName,
    required this.healthStatus,
    required this.airTemp,
    required this.soilHumidity,
    required this.soilNutrients,
    required this.weather,
    required this.tempMax,
    required this.tempMin,
    required this.city,
  });
}

final mockPlantation = PlantationData(
  farmerName: 'Paul Kouamé',
  plotName: 'Plantation GAÏA - Parcelle Nord',
  healthStatus: 'Optimale',
  airTemp: 28.4,
  soilHumidity: 62.0,
  soilNutrients: 78.0,
  weather: 'Ensoleillé',
  tempMax: 32.0,
  tempMin: 24.0,
  city: 'Yamoussoukro',
);

// ─── Alerts ───────────────────────────────────────────────────────────────────

enum AlertType { info, warning, success }

class AlertModel {
  final String message;
  final AlertType type;
  final DateTime time;

  const AlertModel({
    required this.message,
    required this.type,
    required this.time,
  });
}

final List<AlertModel> mockAlerts = [
  AlertModel(
    message:
        'Humidité optimale détectée. Pas d\'irrigation nécessaire aujourd\'hui.',
    type: AlertType.success,
    time: DateTime.now().subtract(const Duration(minutes: 15)),
  ),
  AlertModel(
    message: 'Prochain vol drone prévu dans 2h.',
    type: AlertType.info,
    time: DateTime.now().subtract(const Duration(hours: 1)),
  ),
  AlertModel(
    message: 'Période idéale de plantation d\'ombrage ce mois-ci.',
    type: AlertType.info,
    time: DateTime.now().subtract(const Duration(hours: 3)),
  ),
  AlertModel(
    message:
        'Attention : fertilité du sol en légère baisse dans la parcelle Sud.',
    type: AlertType.warning,
    time: DateTime.now().subtract(const Duration(hours: 6)),
  ),
  AlertModel(
    message: 'Récolte estimée : +12 % par rapport à la saison précédente.',
    type: AlertType.success,
    time: DateTime.now().subtract(const Duration(hours: 12)),
  ),
];

// ─── Social Posts ─────────────────────────────────────────────────────────────

class PostModel {
  final String id;
  final String authorName;
  final String authorInitials;
  final Color avatarColor;
  final String content;
  final DateTime postedAt;
  int likes;
  final int comments;
  bool likedByMe;

  PostModel({
    required this.id,
    required this.authorName,
    required this.authorInitials,
    required this.avatarColor,
    required this.content,
    required this.postedAt,
    required this.likes,
    required this.comments,
    this.likedByMe = false,
  });
}

List<PostModel> mockPosts = [
  PostModel(
    id: '1',
    authorName: 'Awa Yao',
    authorInitials: 'AY',
    avatarColor: const Color(0xFF7B1FA2),
    content:
        'Bonne nouvelle ! Ma parcelle a enregistré une hausse de 15 % de rendement cette saison grâce aux conseils de l\'agent GAÏA. La gestion de l\'ombrage fait vraiment la différence. 🌱',
    postedAt: DateTime.now().subtract(const Duration(minutes: 30)),
    likes: 24,
    comments: 5,
  ),
  PostModel(
    id: '2',
    authorName: 'Koffi Paul',
    authorInitials: 'KP',
    avatarColor: const Color(0xFF1565C0),
    content:
        'Question pour la communauté : quelqu\'un a-t-il déjà utilisé le compost de fientes de volaille sur du cacao ? Quels résultats obtenez-vous sur la qualité des cabosses ?',
    postedAt: DateTime.now().subtract(const Duration(hours: 2)),
    likes: 11,
    comments: 8,
  ),
  PostModel(
    id: '3',
    authorName: 'Mariam Traoré',
    authorInitials: 'MT',
    avatarColor: const Color(0xFF00695C),
    content:
        'Le drone a survolé ma plantation ce matin. Les images sont impressionnantes — on voit clairement les zones de stress hydrique. Merci à l\'équipe GAÏA pour cette technologie accessible.',
    postedAt: DateTime.now().subtract(const Duration(hours: 5)),
    likes: 37,
    comments: 12,
  ),
  PostModel(
    id: '4',
    authorName: 'Seydou Bamba',
    authorInitials: 'SB',
    avatarColor: const Color(0xFFE65100),
    content:
        'Rappel : la campagne intermédiaire 2025-2026 est en cours. Le prix bord champ est de 1 200 FCFA/kg. Négociez groupés pour de meilleures conditions avec les acheteurs locaux.',
    postedAt: DateTime.now().subtract(const Duration(hours: 8)),
    likes: 52,
    comments: 19,
  ),
  PostModel(
    id: '5',
    authorName: 'Aminata Coulibaly',
    authorInitials: 'AC',
    avatarColor: const Color(0xFF558B2F),
    content:
        'J\'ai remarqué des taches brunes sur plusieurs feuilles de ma plantation. L\'assistant GAÏA m\'a orientée vers un traitement à la bouillie bordelaise. Résultats après 10 jours : nette amélioration !',
    postedAt: DateTime.now().subtract(const Duration(days: 1)),
    likes: 29,
    comments: 7,
  ),
];

// ─── Cacao Prices ─────────────────────────────────────────────────────────────

class CacaoPriceData {
  final double internationalPrice;
  final double officialCIPrice;
  final double farmGatePrice;
  final double dailyChange;
  final double dailyChangePercent;
  final int contractVolume;
  final DateTime updatedAt;

  const CacaoPriceData({
    required this.internationalPrice,
    required this.officialCIPrice,
    required this.farmGatePrice,
    required this.dailyChange,
    required this.dailyChangePercent,
    required this.contractVolume,
    required this.updatedAt,
  });
}

final mockCacaoPrice = CacaoPriceData(
  internationalPrice: 2437,
  officialCIPrice: 1823,
  farmGatePrice: 1200,
  dailyChange: 107,
  dailyChangePercent: 4.59,
  contractVolume: 32563,
  updatedAt: DateTime.now().subtract(const Duration(minutes: 45)),
);

// ─── News Articles ────────────────────────────────────────────────────────────

class NewsArticle {
  final String title;
  final String source;
  final String region;
  final DateTime date;
  final String body;

  const NewsArticle({
    required this.title,
    required this.source,
    required this.region,
    required this.date,
    required this.body,
  });
}

final List<NewsArticle> mockNews = [
  NewsArticle(
    title:
        'Le prix du cacao bat un nouveau record à la Bourse de New York, portant espoir aux producteurs ivoiriens',
    source: 'AgriBusiness Africa',
    region: 'Côte d\'Ivoire',
    date: DateTime.now().subtract(const Duration(hours: 4)),
    body:
        'Le cacao ivoirien a franchi la barre des 10 000 dollars la tonne à la Bourse de New York cette semaine, '
        'un niveau jamais atteint depuis plus de quarante ans. Cette flambée des cours est attribuée à une offre '
        'mondiale plus faible que prévu, combinée à une demande soutenue des grands chocolatiers européens.\n\n'
        'Pour les planteurs de Côte d\'Ivoire, premier producteur mondial, cette conjoncture représente une '
        'opportunité historique d\'améliorer leurs revenus. Le Conseil Café-Cacao a indiqué qu\'il pourrait '
        'relever le prix bord-champ dès la prochaine campagne principale.\n\n'
        'Les experts recommandent toutefois la prudence, soulignant que la volatilité des marchés peut '
        'rapidement inverser ces gains. Les agriculteurs sont encouragés à diversifier leurs sources de '
        'revenus et à renforcer la qualité de leur production pour bénéficier des primes.',
  ),
  NewsArticle(
    title:
        'Le Conseil Café-Cacao annonce une prime de qualité pour la campagne intermédiaire 2025-2026',
    source: 'Conseil Café-Cacao',
    region: 'Abidjan',
    date: DateTime.now().subtract(const Duration(days: 1)),
    body:
        'Le Conseil Café-Cacao a officialisé hier la mise en place d\'une prime de qualité différenciée '
        'pour la campagne intermédiaire 2025-2026. Cette prime, qui pourra atteindre 150 FCFA par kilogramme '
        'de fèves certifiées, vise à encourager les pratiques agricoles durables et l\'amélioration de la '
        'fermentation.\n\n'
        'Les planteurs souhaitant en bénéficier devront se soumettre à un contrôle qualité effectué par '
        'des inspecteurs agréés avant la mise en sac. GAÏA-Conseil accompagnera ses utilisateurs dans '
        'cette démarche de certification en proposant des guides pratiques directement dans l\'application.\n\n'
        'Cette initiative s\'inscrit dans la stratégie nationale de montée en gamme du cacao ivoirien '
        'et de renforcement de sa compétitivité face aux origines concurrentes.',
  ),
  NewsArticle(
    title:
        'GAÏA-CI déploie 50 nouveaux capteurs IoT dans les plantations de la région du Lôh-Djiboua',
    source: 'Agence GAÏA',
    region: 'Lôh-Djiboua',
    date: DateTime.now().subtract(const Duration(days: 2)),
    body:
        'L\'agence GAÏA-CI a finalisé l\'installation de 50 capteurs connectés dans 12 plantations pilotes '
        'de la région du Lôh-Djiboua. Ces dispositifs mesurent en continu la température du sol, l\'humidité, '
        'les niveaux de nutriments et l\'ensoleillement, transmettant les données en temps réel vers la '
        'plateforme GAÏA-Conseil.\n\n'
        'Les premiers retours des planteurs concernés sont très positifs : grâce aux alertes automatiques, '
        'plusieurs d\'entre eux ont pu intervenir rapidement sur des zones de stress hydrique avant que les '
        'pertes ne deviennent significatives.\n\n'
        'Le déploiement devrait s\'étendre à l\'ensemble des régions cacaoyères d\'ici la fin de l\'année, '
        'avec un objectif de 500 capteurs supplémentaires financés dans le cadre d\'un partenariat '
        'public-privé avec le Ministère de l\'Agriculture.',
  ),
  NewsArticle(
    title:
        'La pourriture brune menace 8 % des exploitations : les bonnes pratiques pour protéger vos cacaoyers',
    source: 'CNRA Côte d\'Ivoire',
    region: 'Zone Centre-Ouest',
    date: DateTime.now().subtract(const Duration(days: 3)),
    body:
        'Les équipes du Centre National de Recherche Agronomique (CNRA) ont relevé une recrudescence de '
        'la pourriture brune (Phytophthora megakarya) dans la zone Centre-Ouest, touchant actuellement '
        'environ 8 % des exploitations surveillées. Les conditions climatiques humides de ces dernières '
        'semaines ont favorisé la propagation du champignon.\n\n'
        'Les bonnes pratiques recommandées sont les suivantes :\n'
        '• Taille sanitaire régulière pour améliorer l\'aération de la canopée.\n'
        '• Ramassage et destruction des cabosses malades hors de la parcelle.\n'
        '• Application préventive de fongicides homologués à base de cuivre dès les premiers signes.\n'
        '• Surveillance accrue pendant les périodes pluvieuses.\n\n'
        'Le CNRA propose des sessions de formation gratuites dans les coopératives partenaires. '
        'Les planteurs utilisant GAÏA-Conseil peuvent signaler une cabosse suspecte directement '
        'via l\'onglet Alertes pour obtenir un diagnostic assisté.',
  ),
];

// ─── Chat ─────────────────────────────────────────────────────────────────────

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  final GaiaMessageKind kind;
  final String? fileUrl;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.kind = GaiaMessageKind.text,
    this.fileUrl,
  });
}

enum GaiaMessageKind { text, attachment, voice }

const List<String> quickSuggestions = [
  'Bonjour, j\'ai besoin d\'une visite d\'agent',
  'Problème avec le drone, il n\'a pas volé',
  'Mon sol semble trop sec',
  'Comment traiter une maladie des feuilles ?',
];

const String _irrigationResponse =
    'D\'après les données de vos capteurs, l\'humidité du sol est à 62 %, ce qui est dans la plage optimale. '
    'Pas besoin d\'irrigation immédiate. Je vous conseille de réévaluer dans 3 jours si la météo reste ensoleillée.';

const String _droneResponse =
    'Le prochain vol de drone est prévu dans 2h. Il couvrira les zones Nord et Est de votre plantation. '
    'Les résultats seront disponibles dans l\'application sous 24h.';

const String _diseaseResponse =
    'Les symptômes que vous décrivez pourraient indiquer une pourriture brune (Phytophthora). '
    'Je vous recommande d\'isoler les plants affectés et de contacter votre agent agricole. '
    'Un traitement à base de bouillie bordelaise peut aider.';

const String _nutrientResponse =
    'Le taux de nutriments de votre sol est à 78 %. Pour maintenir ce niveau, un apport de compost organique '
    'est recommandé en début de saison des pluies. Évitez les engrais chimiques qui peuvent dégrader la biodiversité.';

const String _defaultResponse =
    'Merci pour votre question. Votre agent agricole assigné, M. Koné Bernard, sera notifié et vous contactera '
    'sous 48h. Vous pouvez aussi consulter la bibliothèque de conseils audio dans la section Alertes.';

String getMockAiResponse(String message) {
  final lower = message.toLowerCase();
  if (lower.contains('irrigation') ||
      lower.contains('eau') ||
      lower.contains('sec')) {
    return _irrigationResponse;
  } else if (lower.contains('drone')) {
    return _droneResponse;
  } else if (lower.contains('maladie') ||
      lower.contains('feuille') ||
      lower.contains('tache')) {
    return _diseaseResponse;
  } else if (lower.contains('engrais') ||
      lower.contains('nutriment') ||
      lower.contains('fertilit')) {
    return _nutrientResponse;
  }
  return _defaultResponse;
}

// ─── Admin: Users ─────────────────────────────────────────────────────────────

class AdminUser {
  final String id;
  final String fullName;
  final String email;
  final String region;
  bool isBanned;
  final int plotCount;
  final DateTime joinedAt;

  AdminUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.region,
    this.isBanned = false,
    required this.plotCount,
    required this.joinedAt,
  });

  factory AdminUser.fromRow(Map<String, dynamic> row) {
    return AdminUser(
      id: row['id'].toString(),
      fullName: row['full_name']?.toString() ?? '',
      email: row['email']?.toString() ?? '',
      region: row['region']?.toString() ?? '',
      isBanned: row['is_banned'] as bool? ?? false,
      plotCount: row['plot_count'] as int? ?? 0,
      joinedAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

List<AdminUser> mockAdminUsers = [
  AdminUser(
    id: 'u1',
    fullName: 'Paul Kouamé',
    email: 'paul@gaia-ci.com',
    region: 'Yamoussoukro',
    isBanned: false,
    plotCount: 3,
    joinedAt: DateTime(2024, 1, 15),
  ),
  AdminUser(
    id: 'u2',
    fullName: 'Awa Yao',
    email: 'awa.yao@gaia-ci.com',
    region: 'Abidjan',
    isBanned: false,
    plotCount: 2,
    joinedAt: DateTime(2024, 3, 8),
  ),
  AdminUser(
    id: 'u3',
    fullName: 'Koffi Bamba',
    email: 'koffi.bamba@gaia-ci.com',
    region: 'Daloa',
    isBanned: true,
    plotCount: 1,
    joinedAt: DateTime(2024, 2, 20),
  ),
  AdminUser(
    id: 'u4',
    fullName: 'Mariam Traoré',
    email: 'mariam.traore@gaia-ci.com',
    region: 'Bouaké',
    isBanned: false,
    plotCount: 4,
    joinedAt: DateTime(2023, 11, 5),
  ),
  AdminUser(
    id: 'u5',
    fullName: 'Seydou Coulibaly',
    email: 'seydou.coulibaly@gaia-ci.com',
    region: 'San-Pédro',
    isBanned: false,
    plotCount: 2,
    joinedAt: DateTime(2024, 4, 22),
  ),
];

// ─── Admin: Drones ────────────────────────────────────────────────────────────

enum DroneStatus { online, offline, maintenance }

class DroneModel {
  final String id;
  final String ownerId;
  final String ownerName;
  final DroneStatus status;
  final int batteryLevel;
  final String location;
  final DateTime lastSeen;
  final String? modele;
  final int missionsTotales;
  final double surfaceSurveillee;

  const DroneModel({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.status,
    required this.batteryLevel,
    required this.location,
    required this.lastSeen,
    this.modele,
    this.missionsTotales = 0,
    this.surfaceSurveillee = 0.0,
  });

  factory DroneModel.fromRow(Map<String, dynamic> row) {
    DroneStatus parseStatus(String? s) {
      switch (s) {
        case 'online':
        case 'En ligne':
          return DroneStatus.online;
        case 'maintenance': return DroneStatus.maintenance;
        default: return DroneStatus.offline;
      }
    }

    // Support new schema ('assigned_to', 'last_active') and old mock schema
    // ('owner_id', 'owner_name', 'last_seen') transparently.
    final ownerId = (row['assigned_to'] ?? row['owner_id'] ?? '') as String;
    final lastActiveRaw = (row['last_active'] ?? row['last_seen']) as String?;
    final lastSeen = lastActiveRaw != null
        ? DateTime.tryParse(lastActiveRaw) ?? DateTime.now()
        : DateTime.now();

    return DroneModel(
      id: row['id'] as String,
      ownerId: ownerId,
      ownerName: (row['owner_name'] as String?) ?? '',
      status: parseStatus(row['status'] as String?),
      batteryLevel: (row['battery_level'] as int?) ?? 100,
      location: (row['location'] as String?) ?? '',
      lastSeen: lastSeen,
      modele: row['modele'] as String?,
      missionsTotales: (row['missions_totales'] as int?) ?? 0,
      surfaceSurveillee: (row['surface_surveillee'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

final List<DroneModel> mockDrones = [
  DroneModel(
    id: 'DRONE-001',
    ownerId: 'u1',
    ownerName: 'Paul Kouamé',
    status: DroneStatus.online,
    batteryLevel: 87,
    location: 'Yamoussoukro — Zone Nord',
    lastSeen: DateTime.now().subtract(const Duration(minutes: 5)),
    modele: 'DJI Agras T40',
    missionsTotales: 47,
    surfaceSurveillee: 312.5,
  ),
  DroneModel(
    id: 'DRONE-002',
    ownerId: 'u2',
    ownerName: 'Awa Yao',
    status: DroneStatus.offline,
    batteryLevel: 12,
    location: 'Abidjan — Cocody',
    lastSeen: DateTime.now().subtract(const Duration(hours: 6)),
    modele: 'ABT-7 Pro',
    missionsTotales: 23,
    surfaceSurveillee: 145.0,
  ),
  DroneModel(
    id: 'DRONE-003',
    ownerId: 'u3',
    ownerName: 'Koffi Bamba',
    status: DroneStatus.maintenance,
    batteryLevel: 45,
    location: 'Daloa — Base technique',
    lastSeen: DateTime.now().subtract(const Duration(days: 1)),
    modele: 'Parrot Bluegrass',
    missionsTotales: 31,
    surfaceSurveillee: 198.0,
  ),
  DroneModel(
    id: 'DRONE-004',
    ownerId: 'u4',
    ownerName: 'Mariam Traoré',
    status: DroneStatus.online,
    batteryLevel: 73,
    location: 'Bouaké — Parcelle Est',
    lastSeen: DateTime.now().subtract(const Duration(minutes: 12)),
    modele: 'DJI Agras T20',
    missionsTotales: 15,
    surfaceSurveillee: 89.5,
  ),
  DroneModel(
    id: 'DRONE-005',
    ownerId: 'u5',
    ownerName: 'Seydou Coulibaly',
    status: DroneStatus.offline,
    batteryLevel: 5,
    location: 'San-Pédro — Zone Côtière',
    lastSeen: DateTime.now().subtract(const Duration(hours: 18)),
    modele: 'XAG P100',
    missionsTotales: 8,
    surfaceSurveillee: 42.0,
  ),
];

// ─── Admin: Alerts ────────────────────────────────────────────────────────────

enum AlertSeverity { info, warning, critical }

class AdminAlert {
  final String id;
  final String planteurName;
  final String message;
  final AlertSeverity severity;
  final DateTime createdAt;
  bool isResolved;

  AdminAlert({
    required this.id,
    required this.planteurName,
    required this.message,
    required this.severity,
    required this.createdAt,
    this.isResolved = false,
  });
}

List<AdminAlert> mockAdminAlerts = [
  AdminAlert(
    id: 'a1',
    planteurName: 'Paul Kouamé',
    message:
        'Niveau d\'humidité du sol critique : 18 %. Irrigation urgente recommandée.',
    severity: AlertSeverity.critical,
    createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    isResolved: false,
  ),
  AdminAlert(
    id: 'a2',
    planteurName: 'Awa Yao',
    message: 'Le drone DRONE-002 est hors ligne depuis plus de 6 heures.',
    severity: AlertSeverity.warning,
    createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    isResolved: false,
  ),
  AdminAlert(
    id: 'a3',
    planteurName: 'Koffi Bamba',
    message: 'Compte suspendu. Activité inhabituelle détectée.',
    severity: AlertSeverity.warning,
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    isResolved: false,
  ),
  AdminAlert(
    id: 'a4',
    planteurName: 'Mariam Traoré',
    message: 'Rapport de visite d\'agent soumis avec succès.',
    severity: AlertSeverity.info,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    isResolved: true,
  ),
  AdminAlert(
    id: 'a5',
    planteurName: 'Seydou Coulibaly',
    message: 'Batterie du drone DRONE-005 faible : 5 %. Recharge requise.',
    severity: AlertSeverity.warning,
    createdAt: DateTime.now().subtract(const Duration(hours: 18)),
    isResolved: false,
  ),
];

// ─── Admin: Telemetry ─────────────────────────────────────────────────────────

class TelemetryRecord {
  final String planteurName;
  final double temperature;
  final double airHumidity;
  final double soilHumidity;
  final double soilPH;
  final double nitrogen;
  final DateTime recordedAt;

  const TelemetryRecord({
    required this.planteurName,
    required this.temperature,
    required this.airHumidity,
    required this.soilHumidity,
    required this.soilPH,
    required this.nitrogen,
    required this.recordedAt,
  });
}

final List<TelemetryRecord> mockTelemetry = [
  TelemetryRecord(
    planteurName: 'Paul Kouamé',
    temperature: 28.4,
    airHumidity: 72.0,
    soilHumidity: 18.0,
    soilPH: 6.2,
    nitrogen: 52.0,
    recordedAt: DateTime.now().subtract(const Duration(minutes: 20)),
  ),
  TelemetryRecord(
    planteurName: 'Awa Yao',
    temperature: 31.2,
    airHumidity: 65.0,
    soilHumidity: 55.0,
    soilPH: 5.3,
    nitrogen: 38.0,
    recordedAt: DateTime.now().subtract(const Duration(minutes: 35)),
  ),
  TelemetryRecord(
    planteurName: 'Koffi Bamba',
    temperature: 27.8,
    airHumidity: 80.0,
    soilHumidity: 68.0,
    soilPH: 6.8,
    nitrogen: 61.0,
    recordedAt: DateTime.now().subtract(const Duration(hours: 1)),
  ),
  TelemetryRecord(
    planteurName: 'Mariam Traoré',
    temperature: 33.5,
    airHumidity: 58.0,
    soilHumidity: 42.0,
    soilPH: 7.2,
    nitrogen: 29.0,
    recordedAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  TelemetryRecord(
    planteurName: 'Seydou Coulibaly',
    temperature: 29.1,
    airHumidity: 74.0,
    soilHumidity: 61.0,
    soilPH: 6.5,
    nitrogen: 47.0,
    recordedAt: DateTime.now().subtract(const Duration(hours: 3)),
  ),
];

// ─── Admin: Messages ──────────────────────────────────────────────────────────

class AdminMessage {
  final String id;
  final String fromName;
  final bool fromAdmin;
  final String content;
  final DateTime sentAt;
  final GaiaMessageKind kind;
  final String? fileUrl;
  final String? fileName;
  final String? mimeType;

  const AdminMessage({
    required this.id,
    required this.fromName,
    required this.fromAdmin,
    required this.content,
    required this.sentAt,
    this.kind = GaiaMessageKind.text,
    this.fileUrl,
    this.fileName,
    this.mimeType,
  });
}

Map<String, List<AdminMessage>> mockConversations = {
  'u1': [
    AdminMessage(
      id: 'm1_1',
      fromName: 'Paul Kouamé',
      fromAdmin: false,
      content:
          'Bonjour, mon sol est très sec depuis plusieurs jours. Que faire ?',
      sentAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    AdminMessage(
      id: 'm1_2',
      fromName: 'Administrateur GAÏA',
      fromAdmin: true,
      content:
          'Bonjour Paul, nous avons bien reçu votre message. Une visite d\'agent est programmée pour votre parcelle sous 48h.',
      sentAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AdminMessage(
      id: 'm1_3',
      fromName: 'Paul Kouamé',
      fromAdmin: false,
      content: 'Merci beaucoup, j\'attends la visite avec impatience.',
      sentAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ],
  'u2': [
    AdminMessage(
      id: 'm2_1',
      fromName: 'Awa Yao',
      fromAdmin: false,
      content: 'Mon drone n\'a pas effectué le vol prévu ce matin.',
      sentAt: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    AdminMessage(
      id: 'm2_2',
      fromName: 'Administrateur GAÏA',
      fromAdmin: true,
      content:
          'Nous avons identifié un problème technique avec DRONE-002. Notre équipe est en cours d\'intervention.',
      sentAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
  ],
  'u3': [
    AdminMessage(
      id: 'm3_1',
      fromName: 'Koffi Bamba',
      fromAdmin: false,
      content: 'Pourquoi mon accès est-il suspendu ?',
      sentAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    AdminMessage(
      id: 'm3_2',
      fromName: 'Administrateur GAÏA',
      fromAdmin: true,
      content:
          'Votre compte a été suspendu suite à une activité inhabituelle. Veuillez contacter le support GAÏA pour régulariser votre situation.',
      sentAt: DateTime.now().subtract(const Duration(days: 1, hours: 22)),
    ),
  ],
  'u4': [
    AdminMessage(
      id: 'm4_1',
      fromName: 'Mariam Traoré',
      fromAdmin: false,
      content:
          'J\'ai soumis mon rapport de visite. Pouvez-vous confirmer la réception ?',
      sentAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    AdminMessage(
      id: 'm4_2',
      fromName: 'Administrateur GAÏA',
      fromAdmin: true,
      content: 'Votre demande a bien été reçue et sera traitée sous 48h.',
      sentAt: DateTime.now().subtract(const Duration(hours: 22)),
    ),
  ],
  'u5': [
    AdminMessage(
      id: 'm5_1',
      fromName: 'Seydou Coulibaly',
      fromAdmin: false,
      content:
          'La batterie de mon drone est presque vide. Comment faire pour la recharger ?',
      sentAt: DateTime.now().subtract(const Duration(hours: 20)),
    ),
    AdminMessage(
      id: 'm5_2',
      fromName: 'Administrateur GAÏA',
      fromAdmin: true,
      content:
          'Veuillez ramener le drone à la station de base la plus proche. Un technicien vous assistera.',
      sentAt: DateTime.now().subtract(const Duration(hours: 18)),
    ),
    AdminMessage(
      id: 'm5_3',
      fromName: 'Seydou Coulibaly',
      fromAdmin: false,
      content: 'D\'accord, je me rendrai à la station demain matin.',
      sentAt: DateTime.now().subtract(const Duration(hours: 17)),
    ),
  ],
};

AdminUser _findOrCreateMessagingUser(String fullName) {
  final normalizedName = fullName.trim().isEmpty
      ? 'Utilisateur GAÏA'
      : fullName.trim();

  for (final user in mockAdminUsers) {
    if (user.fullName.toLowerCase() == normalizedName.toLowerCase()) {
      return user;
    }
  }

  final user = AdminUser(
    id: 'u${DateTime.now().microsecondsSinceEpoch}',
    fullName: normalizedName,
    email: '',
    region: 'Région non précisée',
    plotCount: 0,
    joinedAt: DateTime.now(),
  );
  mockAdminUsers.add(user);
  return user;
}

void sendUserMessageToAdmin({
  required String fromName,
  required String content,
  GaiaMessageKind kind = GaiaMessageKind.text,
}) {
  final trimmed = content.trim();
  if (trimmed.isEmpty) return;

  final user = _findOrCreateMessagingUser(fromName);
  final sentAt = DateTime.now();
  mockConversations[user.id] ??= [];
  mockConversations[user.id]!.add(
    AdminMessage(
      id: 'user_${sentAt.microsecondsSinceEpoch}',
      fromName: user.fullName,
      fromAdmin: false,
      content: trimmed,
      sentAt: sentAt,
      kind: kind,
    ),
  );
}

// ─── Admin: Quick Message Templates ──────────────────────────────────────────

const List<String> quickMessageTemplates = [
  'Votre demande a bien été reçue et sera traitée sous 48h.',
  'Une visite d\'agent est programmée pour votre parcelle.',
  'Votre drone a été remis en service avec succès.',
  'Merci pour votre rapport. Nos experts analysent les données.',
  'Rappel : veuillez mettre à jour vos informations de parcelle dans l\'application.',
];
