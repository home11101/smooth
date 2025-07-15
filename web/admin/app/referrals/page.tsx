import { useEffect, useState, useRef } from 'react';
import { createClient } from '@supabase/supabase-js';
import { Box, Typography, Paper, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, TablePagination, TextField, InputAdornment, IconButton, Button, MenuItem, Select, Grid, Divider, Tabs, Tab } from '@mui/material';
import SearchIcon from '@mui/icons-material/Search';
import DownloadIcon from '@mui/icons-material/Download';
import Loader from '../../components/Loader';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import Collapse from '@mui/material/Collapse';
import RefreshIcon from '@mui/icons-material/Refresh';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, LineChart, CartesianGrid, Line } from 'recharts';
import * as React from 'react';

const supabaseUrl = 'https://qlomkoexurbxqsezavdi.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsb21rb2V4dXJieHFzZXphdmRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEzODYxOTYsImV4cCI6MjA2Njk2MjE5Nn0.eVV4vRp1a_5FVMqqRcSHFC5cjaBEOKCODHZQ76fpED8';
const supabase = createClient(supabaseUrl, supabaseKey);

type LotteryEntry = {
  id?: string;
  device_id?: string;
  user_id?: string;
  entry_date?: string;
  [key: string]: any;
};

export default function ReferralsPage() {
  return <div>Test JSX</div>;
} 