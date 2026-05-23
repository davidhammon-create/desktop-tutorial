import React, { createContext, useState, useContext } from 'react';

const DEMO_USER = { id: 'demo-user', email: 'demo@legalos.de', full_name: 'Demo Nutzer', role: 'admin', jurisdiction: 'DE', language: 'DE', onboarding_completed: true, ki_credits: 500, plan: 'professional' };

const AuthContext = createContext();

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(DEMO_USER);
  const value = {
    user, currentUser: user, isAuthenticated: true, isLoadingAuth: false, isLoadingPublicSettings: false,
    authError: null, appPublicSettings: { id: 'demo', public_settings: {} },
    login: async () => setUser(DEMO_USER),
    logout: async () => setUser(null),
    navigateToLogin: () => {},
    updateUser: (data) => setUser(u => ({ ...u, ...data })),
  };
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

export const useAuth = () => useContext(AuthContext);
export default AuthContext;
