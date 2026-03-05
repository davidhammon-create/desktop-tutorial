import { useNavigate } from 'react-router-dom';

export default function KanzleiDashboard() {
  const navigate = useNavigate();
  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center">
      <div className="text-center space-y-4">
        <h1 className="text-2xl font-bold text-gray-900">Kanzlei Dashboard</h1>
        <p className="text-gray-500">Platzhalter-Seite</p>
        <button
          className="text-blue-600 underline text-sm"
          onClick={() => navigate('/')}
        >
          ← Zurück zum Argument Visualizer
        </button>
      </div>
    </div>
  );
}
