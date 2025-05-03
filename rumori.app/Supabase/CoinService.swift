import Foundation
import Supabase

class CoinService: ObservableObject {
    static let shared = CoinService()
    
    private let client = SupabaseManager.shared.client
    @Published var balance: Int = 0
    
    private init() {
        Task { @MainActor in
            do {
                try await fetchBalance()
            } catch {
                print("❌ [CoinService] Error fetching initial balance: \(error)")
            }
        }
    }
    
    @MainActor
    func fetchBalance() async throws {
        guard let userId = AuthService.shared.currentUser?.id else {
            throw AuthError.notAuthenticated
        }
        
        do {
            let response = try await client
                .from("user_coins")
                .select("balance")
                .eq("user_id", value: userId)
                .single()
                .execute()
            
            let decoder = JSONDecoder()
            let data = try decoder.decode(CoinBalance.self, from: response.data)
            balance = data.balance
        } catch {
            // If no balance record exists, create one
            if let postgrestError = error as? PostgrestError,
               postgrestError.code == "PGRST116" {
                try await createInitialBalance(userId: userId)
                balance = 0
            } else {
                throw error
            }
        }
    }
    
    @MainActor
    private func createInitialBalance(userId: UUID) async throws {
        let response = try await client
            .from("user_coins")
            .insert([
                "user_id": AnyJSON.string(userId.uuidString),
                "balance": AnyJSON.double(0)
            ])
            .execute()
        
        if response.status != 201 {
            throw NSError(domain: "CoinService", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to create initial balance"
            ])
        }
    }
    
    @MainActor
    func earnCoins(amount: Int, projectId: UUID, description: String) async throws {
        guard let userId = AuthService.shared.currentUser?.id else {
            throw AuthError.notAuthenticated
        }
        
        do {
            // Start a transaction
            let response = try await client
                .rpc("earn_coins", params: [
                    "p_user_id": AnyJSON.string(userId.uuidString),
                    "p_amount": AnyJSON.double(Double(amount)),
                    "p_project_id": AnyJSON.string(projectId.uuidString),
                    "p_description": AnyJSON.string(description)
                ])
                .execute()
            
            // 200 and 204 are both success status codes
            if response.status != 200 && response.status != 204 {
                print("❌ [CoinService] RPC call failed with status: \(response.status)")
                throw NSError(domain: "CoinService", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to earn coins"
                ])
            }
            
            // Update local balance immediately
            try await fetchBalance()
            print("✅ [CoinService] Balance updated to: \(balance)")
        } catch let error as PostgrestError {
            print("❌ [CoinService] PostgrestError: \(error.message ?? "Unknown error")")
            print("❌ [CoinService] Error code: \(error.code ?? "No code")")
            print("❌ [CoinService] Error details: \(error.detail ?? "No details")")
            print("❌ [CoinService] Error hint: \(error.hint ?? "No hint")")
            throw error
        } catch {
            print("❌ [CoinService] Error earning coins: \(error)")
            throw error
        }
    }
    
    @MainActor
    func spendCoins(amount: Int, projectId: UUID, description: String) async throws {
        guard let userId = AuthService.shared.currentUser?.id else {
            throw AuthError.notAuthenticated
        }
        
        do {
            // Start a transaction
            let response = try await client
                .rpc("spend_coins", params: [
                    "p_user_id": AnyJSON.string(userId.uuidString),
                    "p_amount": AnyJSON.double(Double(amount)),
                    "p_project_id": AnyJSON.string(projectId.uuidString),
                    "p_description": AnyJSON.string(description)
                ])
                .execute()
            
            // 200 and 204 are both success status codes
            if response.status != 200 && response.status != 204 {
                print("❌ [CoinService] RPC call failed with status: \(response.status)")
                throw NSError(domain: "CoinService", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to spend coins"
                ])
            }
            
            // Update local balance immediately
            try await fetchBalance()
            print("✅ [CoinService] Balance updated to: \(balance)")
        } catch let error as PostgrestError {
            print("❌ [CoinService] PostgrestError: \(error.message ?? "Unknown error")")
            print("❌ [CoinService] Error code: \(error.code ?? "No code")")
            print("❌ [CoinService] Error details: \(error.detail ?? "No details")")
            print("❌ [CoinService] Error hint: \(error.hint ?? "No hint")")
            throw error
        } catch {
            print("❌ [CoinService] Error spending coins: \(error)")
            throw error
        }
    }
}

private struct CoinBalance: Codable {
    let balance: Int
} 