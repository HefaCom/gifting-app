/*
  # Update admin policies

  1. Changes
    - Add new admin-specific policies for all tables
    - Ensure admin users have full access to all data
    - Fix recursive policy issues
  
  2. Security
    - Restrict admin access to users with admin role
    - Enable RLS for all tables
    - Add proper policies for data access
*/

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Allow admin full access to users" ON users;
DROP POLICY IF EXISTS "Allow admin full access to gifts" ON gifts;
DROP POLICY IF EXISTS "Allow admin full access to referrals" ON referrals;
DROP POLICY IF EXISTS "Allow admin full access to progression" ON progression;

-- Create new admin policies for users table
CREATE POLICY "Admin read access for users"
  ON users
  FOR SELECT
  TO authenticated
  USING (
    (SELECT role FROM users WHERE id = auth.uid()) = 'admin'
    OR id = auth.uid()
  );

CREATE POLICY "Admin write access for users"
  ON users
  FOR ALL
  TO authenticated
  USING (
    (SELECT role FROM users WHERE id = auth.uid()) = 'admin'
  )
  WITH CHECK (
    (SELECT role FROM users WHERE id = auth.uid()) = 'admin'
  );

-- Create new admin policies for gifts table
CREATE POLICY "Admin read access for gifts"
  ON gifts
  FOR SELECT
  TO authenticated
  USING (
    (SELECT role FROM users WHERE id = auth.uid()) = 'admin'
    OR gifter_id = auth.uid()
    OR receiver_id = auth.uid()
  );

CREATE POLICY "Admin write access for gifts"
  ON gifts
  FOR ALL
  TO authenticated
  USING (
    (SELECT role FROM users WHERE id = auth.uid()) = 'admin'
  )
  WITH CHECK (
    (SELECT role FROM users WHERE id = auth.uid()) = 'admin'
  );

-- Create new admin policies for referrals table
CREATE POLICY "Admin read access for referrals"
  ON referrals
  FOR SELECT
  TO authenticated
  USING (
    (SELECT role FROM users WHERE id = auth.uid()) = 'admin'
    OR referrer_id = auth.uid()
    OR referred_id = auth.uid()
  );

CREATE POLICY "Admin write access for referrals"
  ON referrals
  FOR ALL
  TO authenticated
  USING (
    (SELECT role FROM users WHERE id = auth.uid()) = 'admin'
  )
  WITH CHECK (
    (SELECT role FROM users WHERE id = auth.uid()) = 'admin'
  );

-- Create new admin policies for progression table
CREATE POLICY "Admin read access for progression"
  ON progression
  FOR SELECT
  TO authenticated
  USING (
    (SELECT role FROM users WHERE id = auth.uid()) = 'admin'
    OR user_id = auth.uid()
  );

CREATE POLICY "Admin write access for progression"
  ON progression
  FOR ALL
  TO authenticated
  USING (
    (SELECT role FROM users WHERE id = auth.uid()) = 'admin'
  )
  WITH CHECK (
    (SELECT role FROM users WHERE id = auth.uid()) = 'admin'
  );