/*
  # Add default admin user
  
  1. Changes
    - Insert default admin user with a known referral code
    - Remove the referred_by constraint for this specific user
  
  2. Security
    - No changes to existing RLS policies
*/

-- First, temporarily disable the referred_by constraint
ALTER TABLE users
DROP CONSTRAINT IF EXISTS users_referred_by_required;

-- Insert default admin user if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM users 
    WHERE email = 'admin@gifting.system'
  ) THEN
    INSERT INTO users (
      id,
      full_name,
      email,
      role,
      level,
      referral_code,
      status
    ) VALUES (
      'a98be3f0-0000-4000-a000-000000000000', -- fixed UUID for consistency
      'System Admin',
      'admin@gifting.system',
      'funder',
      'master',
      'ADMIN_REF_CODE', -- fixed referral code that's easy to remember
      'active'
    );
  END IF;
END $$;

-- Re-add the referred_by constraint with an exception for the admin user
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.table_constraints 
    WHERE constraint_name = 'users_referred_by_required'
  ) THEN
    ALTER TABLE users
    ADD CONSTRAINT users_referred_by_required
    CHECK (
      referred_by IS NOT NULL OR 
      email = 'admin@gifting.system'
    );
  END IF;
END $$;