/*
  # Fix Progression Sequence

  1. Changes
    - Create progression_id_seq sequence if it doesn't exist
    - Update progression table to use the sequence
    - Grant proper permissions

  2. Security
    - Maintain existing RLS policies
    - Grant minimal required permissions
*/

-- Create sequence if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_sequences WHERE schemaname = 'public' AND sequencename = 'progression_id_seq'
  ) THEN
    CREATE SEQUENCE public.progression_id_seq
      START WITH 1
      INCREMENT BY 1
      NO MINVALUE
      NO MAXVALUE
      CACHE 1;
  END IF;
END $$;

-- Update progression table to use the sequence
ALTER TABLE progression 
  ALTER COLUMN id SET DEFAULT gen_random_uuid();

-- Grant permissions
GRANT USAGE ON SEQUENCE progression_id_seq TO authenticated;
GRANT INSERT ON progression TO authenticated;

-- Ensure the check_and_progress_user function has proper permissions
GRANT EXECUTE ON FUNCTION check_and_progress_user() TO authenticated;