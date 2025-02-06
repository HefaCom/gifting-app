/*
  # Add admin role and create admin user

  1. Changes
    - Add admin role to user_role enum in a separate transaction
    - Create admin user with proper role

  2. Security
    - Ensure proper transaction handling for enum modification
*/

-- First transaction: Add the enum value
ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'admin';

-- Second transaction: Create or update admin user
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
      'a98be3f0-0000-4000-a000-000000000000',
      'System Admin',
      'admin@gifting.system',
      'admin',
      'master',
      'ADMIN_REF_CODE',
      'active'
    );
  ELSE
    UPDATE users
    SET 
      role = 'admin',
      level = 'master',
      status = 'active'
    WHERE email = 'admin@gifting.system';
  END IF;
END $$;