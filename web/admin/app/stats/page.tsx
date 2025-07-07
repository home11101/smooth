'use client';
import { useEffect, useState } from 'react';
import { createClient } from '@supabase/supabase-js';
import { Box, Typography, Paper, Grid } from '@mui/material';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, PieChart, Pie, Cell, Legend } from 'recharts';

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

  useEffect(() => {
    fetchAll();
  }, []);

  async function fetchAll() {
    const { data: pay } = await supabase.from('payments').select('*');
    setPayments(pay || []);
    const { data: codesData } = await supabase.from('promo_codes').select('*');
    setCodes(codesData || []);
    const { data: usagesData } = await supabase.from('promo_code_usage').select('*');
    setUsages(usagesData || []);
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

  return (
    <Box>
      <Typography variant="h4" gutterBottom>Statistiques</Typography>
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