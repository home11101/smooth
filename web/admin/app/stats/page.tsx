'use client';
import { useEffect, useState } from 'react';
import { createClient } from '@supabase/supabase-js';
import { Box, Typography, Paper, Grid, TextField, MenuItem, Button } from '@mui/material';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, PieChart, Pie, Cell, Legend } from 'recharts';
import Loader from '../../components/Loader';
import PrintIcon from '@mui/icons-material/Print';

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
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
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
    } catch (e: any) {
      setError(e.message || 'Erreur lors du chargement des stats');
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
      <Typography variant="h4" gutterBottom tabIndex={0} sx={{ color: 'text.primary', fontWeight: 'bold' }}>Statistiques</Typography>
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
      </Grid>
    </Box>
  );
} 