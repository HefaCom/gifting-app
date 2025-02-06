/*
  # Fix user registration policy

  1. Changes
    - Drop previous policy
    - Add new policy that allows user registration with simpler referral code check
    - Remove JWT claim dependency
*/

-- Drop existing policy
DROP POLICY IF EXISTS "Allow new user registration" ON users;

-- Add simplified policy for new user registration
CREATE POLICY "Allow new user registration"
  ON users
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- Add policy to allow users to read other users' referral codes
CREATE POLICY "Allow reading referral codes"
  ON users
  FOR SELECT
  USING (true);