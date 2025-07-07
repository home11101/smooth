'use client';
import { useEffect, useState } from 'react';
import { createClient } from '@supabase/supabase-js';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Grid from '@mui/material/Grid';
import Paper from '@mui/material/Paper';
import MonetizationOnIcon from '@mui/icons-material/MonetizationOn';
import PeopleIcon from '@mui/icons-material/People';
import PaymentIcon from '@mui/icons-material/Payment';
import Loader from '../components/Loader';
import Notification from '../components/Notification';
import WelcomeMessage from '../components/WelcomeMessage';

const supabaseUrl = 'https://qlomkoexurbxqsezavdi.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsb21rb2V4dXJieHFzZXphdmRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEzODYxOTYsImV4cCI6MjA2Njk2MjE5Nn0.eVV4vRp1a_5FVMqqRcSHFC5cjaBEOKCODHZQ76fpED8';
const supabase = createClient(supabaseUrl, supabaseKey);

export default function DashboardPage() {
  const [paymentsCount, setPaymentsCount] = useState<number | null>(null);
  const [totalRevenue, setTotalRevenue] = useState<number | null>(null);
  const [uniqueDevices, setUniqueDevices] = useState<number | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [notif, setNotif] = useState<{open: boolean, message: string, severity?: 'success'|'info'|'warning'|'error'}>({open: false, message: ''});

  useEffect(() => {
    async function fetchStats() {
      setLoading(true);
      setError(null);
      try {
        // Nombre total de paiements
        const { count: payments, error: err1 } = await supabase
          .from('payments')
          .select('*', { count: 'exact', head: true });
        if (err1) throw err1;
        setPaymentsCount(payments ?? 0);

        // CA total
        const { data: revenueData, error: err2 } = await supabase
          .from('payments')
          .select('amount');
        if (err2) throw err2;
        const total = revenueData?.reduce((acc: number, p: any) => acc + (parseFloat(p.amount) || 0), 0) ?? 0;
        setTotalRevenue(total);

        // Nombre d'appareils uniques
        const { data: devicesData, error: err3 } = await supabase
          .from('payments')
          .select('device_id');
        if (err3) throw err3;
        const unique = new Set((devicesData ?? []).map((d: any) => d.device_id)).size;
        setUniqueDevices(unique);
      } catch (e: any) {
        setError(e.message || 'Erreur lors du chargement des stats');
        setNotif({open: true, message: e.message || 'Erreur lors du chargement', severity: 'error'});
      } finally {
        setLoading(false);
      }
    }
    fetchStats();
  }, []);

  const handleExportCSV = () => {
    // Export CSV minimal (paiements, CA, devices)
    const csv = [
      ['Statistique', 'Valeur'],
      ['Paiements', paymentsCount],
      ["Chiffre d'affaires", totalRevenue],
      ['Appareils uniques', uniqueDevices],
    ].map(row => row.join(',')).join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'dashboard_stats.csv';
    a.click();
    setNotif({open: true, message: 'Export CSV effectué', severity: 'success'});
  };

  if (loading) return <Loader />;
  if (error) return <Box p={4} color="error.main" aria-live="assertive">{error}</Box>;

  return (
    <Box>
      <WelcomeMessage />
      <Notification open={notif.open} message={notif.message} severity={notif.severity} onClose={() => setNotif({...notif, open: false})} />
      <Typography variant="h4" gutterBottom tabIndex={0}>Dashboard</Typography>
      <Box display="flex" justifyContent="flex-end" mb={2}>
        <button onClick={handleExportCSV} style={{background:'#2196F3',color:'#fff',border:'none',padding:'8px 16px',borderRadius:4,cursor:'pointer'}} aria-label="Exporter les stats en CSV">Export CSV</button>
      </Box>
      <Grid container spacing={3}>
        <Grid item xs={12} md={4}>
          <Paper sx={{ p: 3, display: 'flex', alignItems: 'center', gap: 2, bgcolor: 'primary.main', color: 'primary.contrastText' }}>
            <PaymentIcon fontSize="large" aria-label="Paiements" />
            <Box>
              <Typography variant="h6">Paiements</Typography>
              <Typography variant="h4">{paymentsCount !== null ? paymentsCount : '...'}</Typography>
            </Box>
          </Paper>
        </Grid>
        <Grid item xs={12} md={4}>
          <Paper sx={{ p: 3, display: 'flex', alignItems: 'center', gap: 2, bgcolor: 'primary.main', color: 'primary.contrastText' }}>
            <MonetizationOnIcon fontSize="large" aria-label="Chiffre d'affaires" />
            <Box>
              <Typography variant="h6">Chiffre d'affaires</Typography>
              <Typography variant="h4">{totalRevenue !== null ? totalRevenue.toFixed(2) + ' €' : '...'}</Typography>
            </Box>
          </Paper>
        </Grid>
        <Grid item xs={12} md={4}>
          <Paper sx={{ p: 3, display: 'flex', alignItems: 'center', gap: 2, bgcolor: 'primary.main', color: 'primary.contrastText' }}>
            <PeopleIcon fontSize="large" aria-label="Appareils uniques" />
            <Box>
              <Typography variant="h6">Appareils uniques</Typography>
              <Typography variant="h4">{uniqueDevices !== null ? uniqueDevices : '...'}</Typography>
            </Box>
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
}
