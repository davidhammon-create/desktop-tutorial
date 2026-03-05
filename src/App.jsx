import { BrowserRouter, Routes, Route } from 'react-router-dom';
import ArgumentVisualizer from './pages/ArgumentVisualizer';
import KanzleiDashboard from './pages/KanzleiDashboard';

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<ArgumentVisualizer />} />
        <Route path="/kanzlei-dashboard" element={<KanzleiDashboard />} />
        <Route path="*" element={<ArgumentVisualizer />} />
      </Routes>
    </BrowserRouter>
  );
}
