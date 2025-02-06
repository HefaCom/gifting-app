/*
  # Fix authentication and policies

  1. Changes
    - Drop existing policies
    - Add new policies for public access during registration
    - Add policy for admin user creation
    - Update referrals policies
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Enable read access for all users" ON users;
DROP POLICY IF EXISTS "Enable insert for registration" ON users;
DROP POLICY IF EXISTS "Enable update for users" ON users;
DROP POLICY IF EXISTS "Enable insert for referrals" ON referrals;

-- Create new policies
CREATE POLICY "Allow public read access"
  ON users
  FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Allow public registration"
  ON users
  FOR INSERT
  TO public
  WITH CHECK (true);

CREATE POLICY "Allow authenticated updates"
  ON users
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Update referrals policies
CREATE POLICY "Allow public referral creation"
  ON referrals
  FOR INSERT
  TO public
  WITH CHECK (true);

CREATE POLICY "Allow referral reading"
  ON referrals
  FOR SELECT
  TO public
  USING (true);

-- Disable email confirmation requirement
ALTER TABLE auth.users
ALTER COLUMN email_confirmed_at
SET DEFAULT now();