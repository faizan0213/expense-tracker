class SupabaseConfig {
  // Replace these with your actual Supabase project credentials
  // You can find these in your Supabase project settings
  static const String supabaseUrl = 'https://your-project-url.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key-here';
  
  // Table names
  static const String expensesTable = 'expenses';
  static const String categoriesTable = 'categories';
  
  // Note: To get your Supabase credentials:
  // 1. Go to https://supabase.com/dashboard
  // 2. Select your project
  // 3. Go to Settings > API
  // 4. Copy the URL and anon/public key
  // 5. Replace the values above
}