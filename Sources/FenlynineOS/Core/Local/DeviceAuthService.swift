import Foundation

// MARK: - Optionale Base44-Session pro Gerät (für Functions; KI oft auch ohne Token)

enum DeviceAuthService {

/// Versucht im Hintergrund Login/Register -- blockiert die App nicht bei Fehlern.
/// Nur wenn Residenz Cloud-Egress erlaubt (kein stilles Cloud-Register bei Offline-first).
@MainActor
static func ensureBase44Session(authManager: AuthManager) async {
  guard AppDefaults.geraeteModusAktiv else { return }
  guard DatenResidenz.darfCloud else { return }

  if FenlynineOSKeychain.get(account: .base44AccessToken) != nil {
    await authManager.refreshBase44SessionIfPossible()
    return
  }

  do {
    try await authManager.login(email: DeviceIdentity.base44Email, password: DeviceIdentity.secret)
  } catch {
    do {
      try await authManager.register(
        email: DeviceIdentity.base44Email,
        password: DeviceIdentity.secret,
        name: DeviceIdentity.anzeigeName,
        kanzlei: "FenlynineOS Gerät"
      )
    } catch {
      // KI (InvokeLLM) funktioniert auf dieser Kopie oft ohne Token -- App bleibt nutzbar.
    }
  }
}
}

