'use client';
import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { createClient } from '@supabase/supabase-js';
import { Box, Typography, TextField, Button, Paper, Alert } from '@mui/material';

const supabaseUrl = 'https://qlomkoexurbxqsezavdi.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsb21rb2V4dXJieHFzZXphdmRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEzODYxOTYsImV4cCI6MjA2Njk2MjE5Nn0.eVV4vRp1a_5FVMqqRcSHFC5cjaBEOKCODHZQ76fpED8';
const supabase = createClient(supabaseUrl, supabaseKey);

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    supabase.auth.getSession().then(({ data }) => {
      if (data.session) {
        router.replace('/');
      }
    });
  }, [router]);

  async function handleLogin(e: any) {
    e.preventDefault();
    setLoading(true);
    setError('');
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    setLoading(false);
    if (error) {
      setError(error.message);
    } else {
      router.replace('/');
    }
  }

  return (
    <Box sx={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', bgcolor: '#F4F6FA' }}>
      <Paper sx={{ p: 4, minWidth: 350, boxShadow: 3 }}>
        <Typography variant="h5" gutterBottom>Connexion Admin</Typography>
        <form onSubmit={handleLogin} style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
          <TextField label="Email" type="email" value={email} onChange={e => setEmail(e.target.value)} required fullWidth />
          <TextField label="Mot de passe" type="password" value={password} onChange={e => setPassword(e.target.value)} required fullWidth />
          {error && <Alert severity="error">{error}</Alert>}
          <Button type="submit" variant="contained" color="primary" disabled={loading} fullWidth>
            {loading ? 'Connexion...' : 'Se connecter'}
          </Button>
        </form>
      </Paper>
    </Box>
  );
} 