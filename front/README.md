# amap-en-ligne — Flutter app

Front for AmapEnLigne. See [`../README.md`](../README.md) for the full project overview.

The flutter app targets Android, iOS and Web.


## User data export

Authenticated users can export their local offline cache from the **Preferences** screen. The app packages the current local SQLite database into a `.zip` archive containing `amap_en_ligne.sqlite`; on web it downloads in the browser, and on native platforms it is saved to the device downloads directory when available.

