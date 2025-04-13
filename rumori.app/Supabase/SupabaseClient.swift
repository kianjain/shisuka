import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: "https://ktgbpungskpjngopzarg.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt0Z2JwdW5nc2twam5nb3B6YXJnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM1ODU1MjgsImV4cCI6MjA1OTE2MTUyOH0.OhnWtlSyX0bUze2mboyA0Mu9wzZt0JuiPNppy0Ph7To"
        )
    }
} 