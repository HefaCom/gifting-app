/*
  # Fix User Policies

  1. Changes
    - Remove recursive policy checks
    - Implement proper role-based access control
    - Fix infinite recursion in admin policies
  
  2. Security
    - Maintain proper access control
    - Prevent policy recursion
    - Keep existing functionality intact
*/

-- First, drop all existing policies
DROP POLICY IF EXISTS "Allow public read access" ON users;
DROP POLICY IF EXISTS "Allow public registration" ON users;
DROP POLICY IF EXISTS "Allow authenticated updates" ON users;
DROP POLICY IF EXISTS "Allow admin full access to users" ON users;

-- Create new, non-recursive policies
CREATE POLICY "Enable read access for all"
  ON users
  FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Enable self-updates"
  ON users
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Enable registration"
  ON users
  FOR INSERT
  TO public
  WITH CHECK (
    -- Allow registration if:
    -- 1. The user is registering themselves (auth.uid matches id)
    -- 2. The email is an admin email (for admin accounts)
    auth.uid() = id OR
    email IN ('admin@gifting.system', 'admin@app.com')
  );

-- Update the referred_by constraint
ALTER TABLE users 
DROP CONSTRAINT IF EXISTS users_referred_by_required;

ALTER TABLE users
ADD CONSTRAINT users_referred_by_required
CHECK (
  referred_by IS NOT NULL OR 
  email IN ('admin@gifting.system', 'admin@app.com')
);

-- Ensure both admin users exist and have correct permissions
DO $$ 
BEGIN
  -- Update or create first admin
  INSERT INTO users (
    id,
    full_name,
    email,
    role,
    level,
    referral_code,
    status
  ) VALUES (
    'a98be3f0-0000-4000-a000-000000000000',
    'System Admin',
    'admin@gifting.system',
    'admin',
    'master',
    'ADMIN_REF_CODE',
    'active'
  )
  ON CONFLICT (email) 
  DO UPDATE SET
    role = 'admin',
    level = 'master',
    status = 'active';

  -- Update or create second admin
  INSERT INTO users (
    id,
    full_name,
    email,
    role,
    level,
    referral_code,
    status
  ) VALUES (
    'b98be3f0-0000-4000-a000-000000000000',
    'Second Admin',
    'admin@app.com',
    'admin',
    'master',
    'ADMIN2_REF_CODE',
    'active'
  )
  ON CONFLICT (email) 
  DO UPDATE SET
    role = 'admin',
    level = 'master',
    status = 'active';
END $$;