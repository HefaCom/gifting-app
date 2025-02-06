/*
  # Add policy for reading admin referral code

  1. Changes
    - Add policy to allow reading admin user data for referral code verification
    - This allows unauthenticated users to verify referral codes during signup
*/

-- Add policy to allow reading user data for referral code verification
CREATE POLICY "Allow reading user data for referral code verification"
  ON users
  FOR SELECT
  TO anon
  USING (true)
  WITH CHECK (true);

-- Add policy to allow reading user data for referral code verification for authenticated users
CREATE POLICY "Allow reading user data for referral code verification for authenticated users"
  ON users
  FOR SELECT
  TO authenticated
  USING (true)
  WITH CHECK (true);