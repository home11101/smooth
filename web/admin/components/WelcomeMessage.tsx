'use client';
import { useEffect, useState } from 'react';
import { createClient } from '@supabase/supabase-js';
import { Box, Typography, TextField, Button, CircularProgress } from '@mui/material';
import Notification from './Notification';

const supabaseUrl = 'https://qlomkoexurbxqsezavdi.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsb21rb2V4dXJieHFzZXphdmRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEzODYxOTYsImV4cCI6MjA2Njk2MjE5Nn0.eVV4vRp1a_5FVMqqRcSHFC5cjaBEOKCODHZQ76fpED8';
const supabase = createClient(supabaseUrl, supabaseKey);

export default function WelcomeMessage() {
  const [message, setMessage] = useState('');
  const [editing, setEditing] = useState(false);
  const [loading, setLoading] = useState(true);
  const [notif, setNotif] = useState({ open: false, message: '', severity: 'info' as 'info'|'success'|'error' });

  useEffect(() => {
    fetchMessage();
  }, []);

  async function fetchMessage() {
    setLoading(true);
    const { data, error } = await supabase.from('admin_settings').select('value').eq('key', 'welcome_message').single();
    if (error) {
      setNotif({ open: true, message: error.message, severity: 'error' });
    } else {
      setMessage(data?.value || '');
    }
    setLoading(false);
  }

  async function saveMessage() {
    setLoading(true);
    const { error } = await supabase.from('admin_settings').update({ value: message, updated_at: new Date().toISOString() }).eq('key', 'welcome_message');
    if (error) {
      setNotif({ open: true, message: error.message, severity: 'error' });
    } else {
      setNotif({ open: true, message: 'Message mis à jour !', severity: 'success' });
      setEditing(false);
    }
    setLoading(false);
  }

  if (loading) return <Box display="flex" alignItems="center" gap={1}><CircularProgress size={20} /> Chargement du message...</Box>;

  return (
    <Box mb={3} aria-live="polite">
      <Notification open={notif.open} message={notif.message} severity={notif.severity} onClose={() => setNotif({ ...notif, open: false })} />
      {editing ? (
        <Box display="flex" gap={2} alignItems="center">
          <TextField value={message} onChange={e => setMessage(e.target.value)} size="small" label="Message d'accueil" inputProps={{ tabIndex: 0 }} />
          <Button onClick={saveMessage} variant="contained" color="primary" tabIndex={0}>Enregistrer</Button>
          <Button onClick={() => setEditing(false)} variant="outlined" tabIndex={0}>Annuler</Button>
        </Box>
      ) : (
        <Box display="flex" gap={2} alignItems="center">
          <Typography variant="h6" tabIndex={0}>{message}</Typography>
          <Button onClick={() => setEditing(true)} variant="outlined" size="small" tabIndex={0}>Modifier</Button>
        </Box>
      )}
    </Box>
  );
} 