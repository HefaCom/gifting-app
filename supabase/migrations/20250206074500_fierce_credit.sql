/*
  # Fix referral code verification policy

  1. Changes
    - Remove invalid WITH CHECK clauses from SELECT policies
    - Add proper policies for referral code verification
*/

-- Drop existing incorrect policies if they exist
DROP POLICY IF EXISTS "Allow reading user data for referral code verification" ON users;
DROP POLICY IF EXISTS "Allow reading user data for referral code verification for authenticated users" ON users;

-- Add corrected policies
CREATE POLICY "Allow reading user data for referral code verification"
  ON users
  FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Allow reading user data for referral code verification for authenticated users"
  ON users
  FOR SELECT
  TO authenticated
  USING (true);