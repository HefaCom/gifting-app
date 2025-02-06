/*
  # Gifting System Schema

  1. New Tables
    - users
      - Core user information and their role/level in the system
    - referrals
      - Tracks referral relationships between users
    - gifts
      - Records gift transactions between users
    - progression
      - Logs user level progression history

  2. Enums
    - user_role: gifter, receiver, funder
    - user_level: gifter, beginner, apprentice, advanced, teacher, master
    - referral_status: pending, completed
    - gift_status: pending, completed

  3. Security
    - Enable RLS on all tables
    - Policies for user access control
    - Policies for referral validation
    - Policies for gift transactions
*/

-- Create ENUMs
CREATE TYPE user_role AS ENUM ('gifter', 'receiver', 'funder');
CREATE TYPE user_level AS ENUM ('gifter', 'beginner', 'apprentice', 'advanced', 'teacher', 'master');
CREATE TYPE referral_status AS ENUM ('pending', 'completed');
CREATE TYPE gift_status AS ENUM ('pending', 'completed');

-- Create users table
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  role user_role NOT NULL DEFAULT 'gifter',
  level user_level NOT NULL DEFAULT 'gifter',
  referral_code TEXT UNIQUE DEFAULT encode(gen_random_bytes(9), 'base64'),
  referred_by UUID REFERENCES users(id),
  status TEXT NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create referrals table
CREATE TABLE IF NOT EXISTS referrals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  referrer_id UUID NOT NULL REFERENCES users(id),
  referred_id UUID REFERENCES users(id),
  status referral_status NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create gifts table
CREATE TABLE IF NOT EXISTS gifts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  gifter_id UUID NOT NULL REFERENCES users(id),
  receiver_id UUID NOT NULL REFERENCES users(id),
  level user_level NOT NULL,
  status gift_status NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create progression table
CREATE TABLE IF NOT EXISTS progression (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  old_level user_level NOT NULL,
  new_level user_level NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE gifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE progression ENABLE ROW LEVEL SECURITY;

-- Users policies
CREATE POLICY "Users can read their own data"
  ON users
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own data"
  ON users
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

-- Referrals policies
CREATE POLICY "Users can read their referrals"
  ON referrals
  FOR SELECT
  TO authenticated
  USING (
    auth.uid() = referrer_id OR 
    auth.uid() = referred_id
  );

CREATE POLICY "Users can create referrals"
  ON referrals
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = referrer_id);

-- Gifts policies
CREATE POLICY "Users can read their gifts"
  ON gifts
  FOR SELECT
  TO authenticated
  USING (
    auth.uid() = gifter_id OR 
    auth.uid() = receiver_id
  );

CREATE POLICY "Users can create gifts"
  ON gifts
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = gifter_id);

-- Progression policies
CREATE POLICY "Users can read their progression"
  ON progression
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Functions
CREATE OR REPLACE FUNCTION check_and_progress_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if user has received 8 gifts at their current level
  IF (
    SELECT COUNT(*)
    FROM gifts
    WHERE receiver_id = NEW.receiver_id
    AND level = (SELECT level FROM users WHERE id = NEW.receiver_id)
    AND status = 'completed'
  ) >= 8 THEN
    -- Get current level and determine next level
    WITH user_current_level AS (
      SELECT level
      FROM users
      WHERE id = NEW.receiver_id
    ),
    next_level AS (
      CASE 
        WHEN user_current_level.level = 'beginner' THEN 'apprentice'
        WHEN user_current_level.level = 'apprentice' THEN 'advanced'
        WHEN user_current_level.level = 'advanced' THEN 'teacher'
        WHEN user_current_level.level = 'teacher' THEN 'master'
        WHEN user_current_level.level = 'master' THEN 'gifter'
        ELSE user_current_level.level
      END
    )
    -- Record progression
    INSERT INTO progression (user_id, old_level, new_level)
    VALUES (
      NEW.receiver_id,
      (SELECT level FROM users WHERE id = NEW.receiver_id),
      next_level
    );
    
    -- Update user level
    UPDATE users
    SET level = next_level
    WHERE id = NEW.receiver_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for user progression
CREATE TRIGGER check_user_progression
AFTER INSERT OR UPDATE ON gifts
FOR EACH ROW
EXECUTE FUNCTION check_and_progress_user();