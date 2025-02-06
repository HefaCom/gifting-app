-- Drop existing policies for progression table
DROP POLICY IF EXISTS "progression_admin_select" ON progression;
DROP POLICY IF EXISTS "progression_admin_all" ON progression;

-- Create new policies for progression table
CREATE POLICY "progression_select"
  ON progression
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND email IN ('admin@gifting.system', 'admin@app.com')
    )
    OR user_id = auth.uid()
  );

CREATE POLICY "progression_insert"
  ON progression
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Drop and recreate the trigger function with proper permissions
DROP TRIGGER IF EXISTS check_user_progression ON gifts;
DROP FUNCTION IF EXISTS check_and_progress_user();

CREATE OR REPLACE FUNCTION check_and_progress_user()
RETURNS TRIGGER AS $$
DECLARE
  current_level user_level;
  next_level user_level;
  progression_id uuid;
BEGIN
  -- Get current level
  SELECT level INTO current_level
  FROM users
  WHERE id = NEW.receiver_id;

  -- Check if user has received 8 gifts at their current level
  IF (
    SELECT COUNT(*)
    FROM gifts
    WHERE receiver_id = NEW.receiver_id
    AND level = current_level
    AND status = 'completed'
  ) >= 8 THEN
    -- Determine next level
    next_level := CASE current_level
      WHEN 'gifter' THEN 'beginner'::user_level
      WHEN 'beginner' THEN 'apprentice'::user_level
      WHEN 'apprentice' THEN 'advanced'::user_level
      WHEN 'advanced' THEN 'teacher'::user_level
      WHEN 'teacher' THEN 'master'::user_level
      WHEN 'master' THEN 'gifter'::user_level
      ELSE current_level
    END;

    -- Record progression with SECURITY DEFINER
    INSERT INTO progression (user_id, old_level, new_level)
    VALUES (NEW.receiver_id, current_level, next_level)
    RETURNING id INTO progression_id;
    
    -- Update user level
    UPDATE users
    SET level = next_level
    WHERE id = NEW.receiver_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger
CREATE TRIGGER check_user_progression
AFTER INSERT OR UPDATE ON gifts
FOR EACH ROW
EXECUTE FUNCTION check_and_progress_user();

-- Grant necessary permissions
GRANT USAGE ON SEQUENCE progression_id_seq TO authenticated;
GRANT INSERT ON progression TO authenticated;