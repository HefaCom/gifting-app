/*
  # Remove Hierarchy System

  1. Changes
    - Remove level and progression-related columns and tables
    - Simplify user roles
    - Update existing data
    - Remove triggers and functions

  2. Security
    - Maintain existing RLS policies
    - Keep core functionality intact
*/

-- First, drop the progression-related objects
DROP TRIGGER IF EXISTS check_user_progression ON gifts;
DROP FUNCTION IF EXISTS check_and_progress_user();
DROP TABLE IF EXISTS progression;
DROP SEQUENCE IF EXISTS progression_id_seq;

-- Modify the gifts table to remove level
ALTER TABLE gifts DROP COLUMN IF EXISTS level;

-- Modify the users table
ALTER TABLE users 
  DROP COLUMN IF EXISTS level,
  ALTER COLUMN role TYPE text,
  ALTER COLUMN role SET DEFAULT 'user';

-- Update existing users
UPDATE users
SET role = CASE 
  WHEN role IN ('admin', 'funder') THEN role 
  ELSE 'user' 
END;

-- Create type for simplified roles
DO $$ 
BEGIN
  DROP TYPE IF EXISTS user_role CASCADE;
  CREATE TYPE user_role AS ENUM ('user', 'funder', 'admin');
  
  -- Convert role column to use new enum
  ALTER TABLE users 
    ALTER COLUMN role TYPE user_role 
    USING role::user_role;
END $$;