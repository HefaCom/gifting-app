/*
  # Fix registration policies

  1. Changes
    - Drop previous policies
    - Add new policies that allow unauthenticated registration
    - Simplify the policy structure
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Allow new user registration" ON users;
DROP POLICY IF EXISTS "Allow reading referral codes" ON users;
DROP POLICY IF EXISTS "Users can read their own data" ON users;
DROP POLICY IF EXISTS "Users can update their own data" ON users;

-- Create new policies
CREATE POLICY "Enable read access for all users"
  ON users
  FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Enable insert for registration"
  ON users
  FOR INSERT
  TO public
  WITH CHECK (true);

CREATE POLICY "Enable update for users"
  ON users
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Update referrals policies
DROP POLICY IF EXISTS "Users can create referrals" ON referrals;

CREATE POLICY "Enable insert for referrals"
  ON referrals
  FOR INSERT
  TO public
  WITH CHECK (true);