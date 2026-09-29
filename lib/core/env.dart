// Publishable anahtar istemcide durmak için tasarlanmıştır; veriyi RLS korur.
// Farklı bir proje için: --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_KEY=...
const supabaseUrl = String.fromEnvironment('SUPABASE_URL',
    defaultValue: 'https://nbwddogqixmnsysihktl.supabase.co');
const supabaseKey = String.fromEnvironment('SUPABASE_KEY',
    defaultValue: 'sb_publishable_pnRVSy0Yt8tuH7CltHdDaQ_MShM4iAH');

/// main() Supabase'i başlatınca true olur; testlerde senkronizasyon kapalı kalır.
bool supabaseReady = false;
