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
import DownloadIcon from '@mui/icons-material/Download';
import StoreIcon from '@mui/icons-material/Store';
import TrendingUpIcon from '@mui/icons-material/TrendingUp';
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
  const [totalUsers, setTotalUsers] = useState<number | null>(null);
  const [premiumUsers, setPremiumUsers] = useState<number | null>(null);
  const [totalDownloads, setTotalDownloads] = useState<number | null>(null);
  const [iosDownloads, setIosDownloads] = useState<number | null>(null);
  const [androidDownloads, setAndroidDownloads] = useState<number | null>(null);
  const [webDownloads, setWebDownloads] = useState<number | null>(null);
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

        // Statistiques utilisateurs
        const { data: usersData, error: err4 } = await supabase
          .from('app_users_analytics')
          .select('*')
          .single();
        if (err4) {
          console.log('Table app_users_analytics non trouvée, utilisation de données par défaut');
          setTotalUsers(0);
          setPremiumUsers(0);
        } else {
          setTotalUsers(usersData?.total_users ?? 0);
          setPremiumUsers(usersData?.premium_users ?? 0);
        }

        // Statistiques téléchargements
        const { data: downloadsData, error: err5 } = await supabase
          .from('app_downloads_analytics')
          .select('*');
        if (err5) {
          console.log('Table app_downloads_analytics non trouvée, utilisation de données par défaut');
          setTotalDownloads(0);
          setIosDownloads(0);
          setAndroidDownloads(0);
          setWebDownloads(0);
        } else {
          const total = downloadsData?.reduce((acc: number, d: any) => acc + (d.total_downloads || 0), 0) ?? 0;
          setTotalDownloads(total);
          
          const ios = downloadsData?.find((d: any) => d.platform === 'ios')?.total_downloads ?? 0;
          const android = downloadsData?.find((d: any) => d.platform === 'android')?.total_downloads ?? 0;
          const web = downloadsData?.find((d: any) => d.platform === 'web')?.total_downloads ?? 0;
          
          setIosDownloads(ios);
          setAndroidDownloads(android);
          setWebDownloads(web);
        }
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
    // Export CSV complet avec toutes les statistiques
    const csv = [
      ['Statistique', 'Valeur'],
      ['Paiements', paymentsCount],
      ["Chiffre d'affaires", totalRevenue],
      ['Appareils uniques', uniqueDevices],
      ['Utilisateurs totaux', totalUsers],
      ['Utilisateurs premium', premiumUsers],
      ['Téléchargements totaux', totalDownloads],
      ['Téléchargements iOS', iosDownloads],
      ['Téléchargements Android', androidDownloads],
      ['Téléchargements Web', webDownloads],
    ].map(row => row.join(',')).join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'dashboard_stats_complete.csv';
    a.click();
    setNotif({open: true, message: 'Export CSV effectué', severity: 'success'});
  };

  if (loading) return <Loader />;
  if (error) return <Box p={4} color="error.main" aria-live="assertive">{error}</Box>;

  return (
    <Box>
      <WelcomeMessage />
      <Notification open={notif.open} message={notif.message} severity={notif.severity} onClose={() => setNotif({...notif, open: false})} />
      <Typography variant="h4" gutterBottom tabIndex={0} sx={{ color: 'text.primary', fontWeight: 'bold' }}>Dashboard</Typography>
      <Box display="flex" justifyContent="flex-end" mb={2}>
        <button onClick={handleExportCSV} style={{background:'#2196F3',color:'#fff',border:'none',padding:'8px 16px',borderRadius:4,cursor:'pointer'}} aria-label="Exporter les stats en CSV">Export CSV</button>
      </Box>
      <Grid container spacing={3}>
        {/* Section Paiements */}
        <Grid item xs={12}>
          <Typography variant="h5" gutterBottom sx={{ color: 'text.primary', fontWeight: 'bold', mt: 3 }}>💰 Paiements & Revenus</Typography>
        </Grid>
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

        {/* Section Utilisateurs */}
        <Grid item xs={12}>
          <Typography variant="h5" gutterBottom sx={{ color: 'text.primary', fontWeight: 'bold', mt: 3 }}>👥 Utilisateurs</Typography>
        </Grid>
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 3, display: 'flex', alignItems: 'center', gap: 2, bgcolor: 'success.main', color: 'success.contrastText' }}>
            <PeopleIcon fontSize="large" aria-label="Utilisateurs totaux" />
            <Box>
              <Typography variant="h6">Utilisateurs totaux</Typography>
              <Typography variant="h4">{totalUsers !== null ? totalUsers : '...'}</Typography>
            </Box>
          </Paper>
        </Grid>
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 3, display: 'flex', alignItems: 'center', gap: 2, bgcolor: 'warning.main', color: 'warning.contrastText' }}>
            <TrendingUpIcon fontSize="large" aria-label="Utilisateurs premium" />
            <Box>
              <Typography variant="h6">Utilisateurs premium</Typography>
              <Typography variant="h4">{premiumUsers !== null ? premiumUsers : '...'}</Typography>
            </Box>
          </Paper>
        </Grid>

        {/* Section Téléchargements */}
        <Grid item xs={12}>
          <Typography variant="h5" gutterBottom sx={{ color: 'text.primary', fontWeight: 'bold', mt: 3 }}>📱 Téléchargements par Store</Typography>
        </Grid>
        <Grid item xs={12} md={3}>
          <Paper sx={{ p: 3, display: 'flex', alignItems: 'center', gap: 2, bgcolor: 'info.main', color: 'info.contrastText' }}>
            <DownloadIcon fontSize="large" aria-label="Téléchargements totaux" />
            <Box>
              <Typography variant="h6">Total</Typography>
              <Typography variant="h4">{totalDownloads !== null ? totalDownloads : '...'}</Typography>
            </Box>
          </Paper>
        </Grid>
        <Grid item xs={12} md={3}>
          <Paper sx={{ p: 3, display: 'flex', alignItems: 'center', gap: 2, bgcolor: '#000000', color: '#ffffff' }}>
            <StoreIcon fontSize="large" aria-label="Téléchargements iOS" />
            <Box>
              <Typography variant="h6">App Store</Typography>
              <Typography variant="h4">{iosDownloads !== null ? iosDownloads : '...'}</Typography>
            </Box>
          </Paper>
        </Grid>
        <Grid item xs={12} md={3}>
          <Paper sx={{ p: 3, display: 'flex', alignItems: 'center', gap: 2, bgcolor: '#01875F', color: '#ffffff' }}>
            <StoreIcon fontSize="large" aria-label="Téléchargements Android" />
            <Box>
              <Typography variant="h6">Play Store</Typography>
              <Typography variant="h4">{androidDownloads !== null ? androidDownloads : '...'}</Typography>
            </Box>
          </Paper>
        </Grid>
        <Grid item xs={12} md={3}>
          <Paper sx={{ p: 3, display: 'flex', alignItems: 'center', gap: 2, bgcolor: '#1976D2', color: '#ffffff' }}>
            <StoreIcon fontSize="large" aria-label="Téléchargements Web" />
            <Box>
              <Typography variant="h6">Web</Typography>
              <Typography variant="h4">{webDownloads !== null ? webDownloads : '...'}</Typography>
            </Box>
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
}
