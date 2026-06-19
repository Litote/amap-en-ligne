import 'package:amap_en_ligne/presentation/sync/sync_offline_listener.dart' show SyncOfflineListener;
import 'package:amap_en_ligne/presentation/sync/sync_status_banner.dart' show SyncStatusBanner;

/// User-facing copy shared by the sync status surfaces
/// ([SyncStatusBanner] and [SyncOfflineListener]).
const String syncServerUnreachableMessage =
    'Serveur injoignable. Vos modifications sont enregistrées sur cet '
    'appareil et seront synchronisées dès que la connexion sera rétablie, '
    'tant que vous ne vous déconnectez pas.';
