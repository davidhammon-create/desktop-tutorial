import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, HashRouter, Routes, Route, Navigate } from "react-router-dom";
declare global {
  interface Window {
    atmosDesktop?: { isDesktop: boolean; platform: string };
  }
}
const Router = window.atmosDesktop?.isDesktop ? HashRouter : BrowserRouter;
import { AuthProvider, useAuth } from "@/hooks/useAuth";
import Index from "./pages/Index";
import LexaraPage from "./pages/Lexara";
import BusinessRiskPage from "./pages/BusinessRisk";
import HomePage from "./pages/Home";
import DocumentAnalysisPage from "./pages/DocumentAnalysis";
import ExecutiveDashboard from "./pages/ExecutiveDashboard";
import Auth from "./pages/Auth";
import ResetPassword from "./pages/ResetPassword";
import NotFound from "./pages/NotFound";
import AtmosPage from "./pages/Atmos";
import "@/atmos/atmos.css";
const queryClient = new QueryClient();
function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { user, loading } = useAuth();
  const devAccess = sessionStorage.getItem("dev-access") === "true";
  if (loading) {
    return (
      <div
        style={{
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          minHeight: "100vh",
          fontFamily: "IBM Plex Sans, sans-serif",
          color: "#86868b",
        }}
      >
        Laden...
      </div>
    );
  }
  if (!user && !devAccess) return <Navigate to="/auth" replace />;
  return <>{children}</>;
}
const AppRoutes = () => (
  <Routes>
    <Route path="/" element={<AtmosPage />} />
    <Route path="/atmos" element={<AtmosPage />} />
    <Route path="/auth" element={<Auth />} />
    <Route path="/reset-password" element={<ResetPassword />} />
    <Route
      path="/home"
      element={
        <ProtectedRoute>
          <HomePage />
        </ProtectedRoute>
      }
    />
    <Route
      path="/lexara"
      element={
        <ProtectedRoute>
          <LexaraPage />
        </ProtectedRoute>
      }
    />
    <Route
      path="/business"
      element={
        <ProtectedRoute>
          <BusinessRiskPage />
        </ProtectedRoute>
      }
    />
    <Route path="/documents" element={<DocumentAnalysisPage />} />
    <Route
      path="/dashboard"
      element={
        <ProtectedRoute>
          <ExecutiveDashboard />
        </ProtectedRoute>
      }
    />
    <Route
      path="/graph"
      element={
        <ProtectedRoute>
          <Index />
        </ProtectedRoute>
      }
    />
    <Route path="*" element={<NotFound />} />
  </Routes>
);
const App = () => (
  <QueryClientProvider client={queryClient}>
    <TooltipProvider>
      <Toaster />
      <Sonner />
      <AuthProvider>
        <Router>
          <AppRoutes />
        </Router>
      </AuthProvider>
    </TooltipProvider>
  </QueryClientProvider>
);
export default App;
