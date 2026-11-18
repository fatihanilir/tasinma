# Reklam SDK'sının kullandığı WorkManager, Room veritabanını yansıma ile oluşturur.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.** { *; }
