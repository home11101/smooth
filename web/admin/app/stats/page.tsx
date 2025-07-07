'use client';
import { useEffect, useState } from 'react';
import { createClient } from '@supabase/supabase-js';
import { Box, Typography, Paper, Grid, TextField, MenuItem, Button } from '@mui/material';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, PieChart, Pie, Cell, Legend } from 'recharts';
import Loader from '../../components/Loader';
import Notification from '../../components/Notification';
import PrintIcon from '@mui/icons-material/Print';
import FadeTransition from '../../components/FadeTransition';

const supabaseUrl = 'https://qlomkoexurbxqsezavdi.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsb21rb2V4dXJieHFzZXphdmRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEzODYxOTYsImV4cCI6MjA2Njk2MjE5Nn0.eVV4vRp1a_5FVMqqRcSHFC5cjaBEOKCODHZQ76fpED8';
const supabase = createClient(supabaseUrl, supabaseKey);

const COLORS = ['#0A192F', '#2196F3', '#FF9800', '#4CAF50', '#E91E63', '#9C27B0', '#FFC107'];

function groupByMonth(data: any[], dateKey: string, valueKey: string) {
  const result: {[key: string]: number} = {};
  data.forEach(item => {
    const date = new Date(item[dateKey]);
    const key = `${date.getFullYear()}-${(date.getMonth()+1).toString().padStart(2, '0')}`;
    result[key] = (result[key] || 0) + (parseFloat(item[valueKey]) || 0);
  });
  return Object.entries(result).map(([month, value]) => ({ month, value }));
}

function groupCountByMonth(data: any[], dateKey: string) {
  const result: {[key: string]: number} = {};
  data.forEach(item => {
    const date = new Date(item[dateKey]);
    const key = `${date.getFullYear()}-${(date.getMonth()+1).toString().padStart(2, '0')}`;
    result[key] = (result[key] || 0) + 1;
  });
  return Object.entries(result).map(([month, count]) => ({ month, count }));
}

export default function StatsPage() {
  const [payments, setPayments] = useState<any[]>([]);
  const [codes, setCodes] = useState<any[]>([]);
  const [usages, setUsages] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [notif, setNotif] = useState<{open: boolean, message: string, severity?: 'success'|'info'|'warning'|'error'}>({open: false, message: ''});
  const [platformFilter, setPlatformFilter] = useState('');
  const [periodFilter, setPeriodFilter] = useState('');

  useEffect(() => {
    fetchAll();
  }, [platformFilter, periodFilter]);

  async function fetchAll() {
    setLoading(true);
    setError(null);
    try {
      const { data: pay, error: err1 } = await supabase.from('payments').select('*');
      if (err1) throw err1;
      const filteredPay = pay?.filter((p: any) =>
        (!platformFilter || p.platform === platformFilter) &&
        (!periodFilter || (p.purchase_date && p.purchase_date.startsWith(periodFilter)))
      ) || [];
      setPayments(filteredPay);
      const { data: codesData, error: err2 } = await supabase.from('promo_codes').select('*');
      if (err2) throw err2;
      setCodes(codesData || []);
      const { data: usagesData, error: err3 } = await supabase.from('promo_code_usage').select('*');
      if (err3) throw err3;
      setUsages(usagesData || []);
    } catch (e: any) {
      setError(e.message || 'Erreur lors du chargement des stats');
      setNotif({open: true, message: e.message || 'Erreur lors du chargement', severity: 'error'});
    } finally {
      setLoading(false);
    }
  }

  // CA par mois
  const revenueByMonth = groupByMonth(payments, 'purchase_date', 'amount');
  // Nombre de paiements par mois
  const countByMonth = groupCountByMonth(payments, 'purchase_date');
  // Répartition par plateforme
  const platformData = Object.entries(payments.reduce((acc, p) => {
    acc[p.platform] = (acc[p.platform] || 0) + 1;
    return acc;
  }, {} as {[key: string]: number})).map(([platform, count]) => ({ platform, count }));
  // Top codes promo utilisés
  type CodeCount = { code: string, count: number };
  const topCodes: CodeCount[] = Object.entries(usages.reduce((acc, u) => {
    acc[u.promo_code_id] = (acc[u.promo_code_id] || 0) + 1;
    return acc;
  }, {} as {[key: string]: number})).map(([codeId, count]) => {
    const code = codes.find((c) => c.id === codeId);
    return { code: code?.code || codeId, count: count as number };
  }).sort((a, b) => b.count - a.count).slice(0, 7);

  const handleExportCSV = () => {
    // Export CSV des paiements filtrés
    const csv = [
      Object.keys(payments[0] || {}).join(','),
      ...payments.map(row => Object.values(row).join(','))
    ].join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'paiements_stats.csv';
    a.click();
    setNotif({open: true, message: 'Export CSV effectué', severity: 'success'});
  };

  const handlePrint = () => {
    window.print();
  };

  // Responsive et accessibilité : grilles, aria, labels
  if (loading) return <Loader />;
  if (error) return <Box p={4} color="error.main" aria-live="assertive">{error}</Box>;

  // Filtres dynamiques
  const uniquePlatforms = Array.from(new Set(payments.map(p => p.platform))).filter(Boolean);
  const uniquePeriods = Array.from(new Set(payments.map(p => (p.purchase_date || '').slice(0,7)))).filter(Boolean);

  return (
    <Box>
      <FadeTransition in={notif.open}>
        <Notification open={notif.open} message={notif.message} severity={notif.severity} onClose={() => setNotif({...notif, open: false})} aria-live="polite" />
      </FadeTransition>
      <Typography variant="h4" gutterBottom tabIndex={0}>Statistiques</Typography>
      <Box display="flex" gap={2} mb={2} flexWrap="wrap">
        <TextField select label="Plateforme" value={platformFilter} onChange={e => setPlatformFilter(e.target.value)} size="small" sx={{minWidth:120}} aria-label="Filtrer par plateforme">
          <MenuItem value="">Toutes</MenuItem>
          {uniquePlatforms.map(p => <MenuItem key={p} value={p}>{p}</MenuItem>)}
        </TextField>
        <TextField select label="Période" value={periodFilter} onChange={e => setPeriodFilter(e.target.value)} size="small" sx={{minWidth:120}} aria-label="Filtrer par période">
          <MenuItem value="">Toutes</MenuItem>
          {uniquePeriods.map(p => <MenuItem key={p} value={p}>{p}</MenuItem>)}
        </TextField>
        <Button onClick={handleExportCSV} variant="contained" color="primary" aria-label="Exporter les paiements en CSV">Export CSV</Button>
        <Button onClick={handlePrint} variant="contained" color="primary" startIcon={<PrintIcon />} aria-label="Imprimer les statistiques" tabIndex={0}>Imprimer</Button>
      </Box>
      <Grid container spacing={4}>
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>Chiffre d'affaires par mois</Typography>
            <ResponsiveContainer width="100%" height={250}>
              <BarChart data={revenueByMonth}>
                <XAxis dataKey="month" />
                <YAxis />
                <Tooltip />
                <Bar dataKey="value" fill="#2196F3" />
              </BarChart>
            </ResponsiveContainer>
          </Paper>
        </Grid>
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>Nombre de paiements par mois</Typography>
            <ResponsiveContainer width="100%" height={250}>
              <BarChart data={countByMonth}>
                <XAxis dataKey="month" />
                <YAxis />
                <Tooltip />
                <Bar dataKey="count" fill="#0A192F" />
              </BarChart>
            </ResponsiveContainer>
          </Paper>
        </Grid>
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>Répartition par plateforme</Typography>
            <ResponsiveContainer width="100%" height={250}>
              <PieChart>
                <Pie data={platformData} dataKey="count" nameKey="platform" cx="50%" cy="50%" outerRadius={80} label>
                  {platformData.map((entry, idx) => (
                    <Cell key={`cell-${idx}`} fill={COLORS[idx % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip />
                <Legend />
              </PieChart>
            </ResponsiveContainer>
          </Paper>
        </Grid>
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>Top codes promo utilisés</Typography>
            <ResponsiveContainer width="100%" height={250}>
              <BarChart data={topCodes} layout="vertical">
                <XAxis type="number" />
                <YAxis dataKey="code" type="category" width={100} />
                <Tooltip />
                <Bar dataKey="count" fill="#FF9800" />
              </BarChart>
            </ResponsiveContainer>
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
} 