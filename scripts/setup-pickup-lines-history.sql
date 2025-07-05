-- Table pour l'historique des générations de pickup lines
CREATE TABLE IF NOT EXISTS pickup_line_history (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  generation_id UUID NOT NULL,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  pickup_line_id TEXT NOT NULL,
  text TEXT NOT NULL,
  category TEXT NOT NULL,
  context TEXT NOT NULL,
  intensity INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Activer RLS
ALTER TABLE pickup_line_history ENABLE ROW LEVEL SECURITY;

-- Politiques RLS
CREATE POLICY "Users can view their own pickup line history" ON pickup_line_history
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own pickup line history" ON pickup_line_history
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_pickup_line_history_user_id ON pickup_line_history(user_id);
CREATE INDEX IF NOT EXISTS idx_pickup_line_history_generation_id ON pickup_line_history(generation_id);
CREATE INDEX IF NOT EXISTS idx_pickup_line_history_created_at ON pickup_line_history(created_at);
