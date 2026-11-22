import React, { useState, useEffect } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { toast } from 'sonner';
import { useNavigate } from 'react-router-dom';
import { T, sans } from '@/components/lexara/theme';
const ResetPassword = () => {
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();
  useEffect(() => {
    const hash = window.location.hash;
    if (!hash.includes('type=recovery')) {
      toast.error('Ungültiger Reset-Link');
      navigate('/auth');
    }
  }, [navigate]);
  const handleReset = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      const { error } = await supabase.auth.updateUser({ password });
      if (error) throw error;
      toast.success('Passwort erfolgreich geändert');
      navigate('/');
    } catch (err: any) {
      toast.error(err.message);
    } finally {
      setLoading(false);
    }
  };
  return (
    <div style={{ background: T.bg, fontFamily: sans, minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <div style={{ width: '100%', maxWidth: 400, padding: 32 }}>
        <div style={{ background: T.surface, borderRadius: 16, padding: 28, border: `1px solid ${T.border}` }}>
          <h2 style={{ fontSize: 20, fontWeight: 600, margin: '0 0 20px', color: T.text, fontFamily: sans }}>Neues Passwort setzen</h2>
          <form onSubmit={handleReset} style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
            <input
              type="password"
              placeholder="Neues Passwort (min. 6 Zeichen)"
              value={password}
              onChange={e => setPassword(e.target.value)}
              required
              minLength={6}
              style={{
                fontFamily: sans, fontSize: 15, padding: '12px 16px',
                border: `1px solid ${T.border}`, borderRadius: 12,
                background: T.surface, outline: 'none', width: '100%', color: T.text,
              }}
            />
            <button type="submit" disabled={loading} style={{
              fontFamily: sans, fontSize: 15, fontWeight: 600, padding: '12px 24px',
              border: 'none', borderRadius: 12, cursor: 'pointer', width: '100%',
              background: '#007aff', color: '#fff', opacity: loading ? 0.6 : 1,
            }}>
              {loading ? '...' : 'Passwort ändern'}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
};
export default ResetPassword;
