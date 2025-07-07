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

const supabaseUrl = 'https://qlomkoexurbxqsezavdi.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsb21rb2V4dXJieHFzZXphdmRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEzODYxOTYsImV4cCI6MjA2Njk2MjE5Nn0.eVV4vRp1a_5FVMqqRcSHFC5cjaBEOKCODHZQ76fpED8';
const supabase = createClient(supabaseUrl, supabaseKey);

export default function DashboardPage() {
  const [paymentsCount, setPaymentsCount] = useState<number | null>(null);
  const [totalRevenue, setTotalRevenue] = useState<number | null>(null);
  const [uniqueDevices, setUniqueDevices] = useState<number | null>(null);

  useEffect(() => {
    async function fetchStats() {
      // Nombre total de paiements
      const { count: payments, error: err1 } = await supabase
        .from('payments')
        .select('*', { count: 'exact', head: true });
      setPaymentsCount(payments ?? 0);

      // CA total
      const { data: revenueData, error: err2 } = await supabase
        .from('payments')
        .select('amount');
      const total = revenueData?.reduce((acc: number, p: any) => acc + (parseFloat(p.amount) || 0), 0) ?? 0;
      setTotalRevenue(total);

      // Nombre d'appareils uniques
      const { data: devicesData, error: err3 } = await supabase
        .from('payments')
        .select('device_id');
      const unique = new Set((devicesData ?? []).map((d: any) => d.device_id)).size;
      setUniqueDevices(unique);
    }
    fetchStats();
  }, []);

  return (
    <Box>
      <Typography variant="h4" gutterBottom>Dashboard</Typography>
      <Grid container spacing={3}>
        <Grid item xs={12} md={4}>
          <Paper sx={{ p: 3, display: 'flex', alignItems: 'center', gap: 2, bgcolor: '#0A192F', color: '#fff' }}>
            <PaymentIcon fontSize="large" />
            <Box>
              <Typography variant="h6">Paiements</Typography>
              <Typography variant="h4">{paymentsCount !== null ? paymentsCount : '...'}</Typography>
            </Box>
          </Paper>
        </Grid>
        <Grid item xs={12} md={4}>
          <Paper sx={{ p: 3, display: 'flex', alignItems: 'center', gap: 2, bgcolor: '#0A192F', color: '#fff' }}>
            <MonetizationOnIcon fontSize="large" />
            <Box>
              <Typography variant="h6">Chiffre d'affaires</Typography>
              <Typography variant="h4">{totalRevenue !== null ? totalRevenue.toFixed(2) + ' €' : '...'}</Typography>
            </Box>
          </Paper>
        </Grid>
        <Grid item xs={12} md={4}>
          <Paper sx={{ p: 3, display: 'flex', alignItems: 'center', gap: 2, bgcolor: '#0A192F', color: '#fff' }}>
            <PeopleIcon fontSize="large" />
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
