/*
  # Add insert policy for users table

  1. Changes
    - Add policy to allow new users to be inserted during sign up
    - Ensure proper RLS for user creation
*/

-- Drop existing policy if it exists
DROP POLICY IF EXISTS "Allow new user registration" ON users;

-- Add policy to allow new user registration
CREATE POLICY "Allow new user registration"
  ON users
  FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = id AND
    EXISTS (
      SELECT 1 FROM users WHERE referral_code = current_setting('request.jwt.claims')::json->>'referral_code'
    )
  );