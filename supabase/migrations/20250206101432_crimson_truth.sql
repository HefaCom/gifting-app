/*
  # Fix recursive policies

  1. Changes
    - Remove recursive policy checks
    - Simplify admin access policies
    - Maintain security while avoiding recursion
  
  2. Security
    - Keep RLS enabled
    - Ensure proper access control
    - Prevent infinite recursion
*/

-- First, drop all existing policies
DROP POLICY IF EXISTS "Admin read access for users" ON users;
DROP POLICY IF EXISTS "Admin write access for users" ON users;
DROP POLICY IF EXISTS "Admin read access for gifts" ON gifts;
DROP POLICY IF EXISTS "Admin write access for gifts" ON gifts;
DROP POLICY IF EXISTS "Admin read access for referrals" ON referrals;
DROP POLICY IF EXISTS "Admin write access for referrals" ON referrals;
DROP POLICY IF EXISTS "Admin read access for progression" ON progression;
DROP POLICY IF EXISTS "Admin write access for progression" ON progression;

-- Create simplified policies for users table
CREATE POLICY "users_admin_select"
  ON users
  FOR SELECT
  TO authenticated
  USING (
    email IN ('admin@gifting.system', 'admin@app.com')
    OR id = auth.uid()
  );

CREATE POLICY "users_admin_all"
  ON users
  FOR ALL
  TO authenticated
  USING (
    email IN ('admin@gifting.system', 'admin@app.com')
  )
  WITH CHECK (
    email IN ('admin@gifting.system', 'admin@app.com')
  );

-- Create simplified policies for gifts table
CREATE POLICY "gifts_admin_select"
  ON gifts
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND email IN ('admin@gifting.system', 'admin@app.com')
    )
    OR gifter_id = auth.uid()
    OR receiver_id = auth.uid()
  );

CREATE POLICY "gifts_admin_all"
  ON gifts
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND email IN ('admin@gifting.system', 'admin@app.com')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND email IN ('admin@gifting.system', 'admin@app.com')
    )
  );

-- Create simplified policies for referrals table
CREATE POLICY "referrals_admin_select"
  ON referrals
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND email IN ('admin@gifting.system', 'admin@app.com')
    )
    OR referrer_id = auth.uid()
    OR referred_id = auth.uid()
  );

CREATE POLICY "referrals_admin_all"
  ON referrals
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND email IN ('admin@gifting.system', 'admin@app.com')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND email IN ('admin@gifting.system', 'admin@app.com')
    )
  );

-- Create simplified policies for progression table
CREATE POLICY "progression_admin_select"
  ON progression
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND email IN ('admin@gifting.system', 'admin@app.com')
    )
    OR user_id = auth.uid()
  );

CREATE POLICY "progression_admin_all"
  ON progression
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND email IN ('admin@gifting.system', 'admin@app.com')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND email IN ('admin@gifting.system', 'admin@app.com')
    )
  );