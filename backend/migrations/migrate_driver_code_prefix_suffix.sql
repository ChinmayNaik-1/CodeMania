ALTER TABLE driver_code
  ADD COLUMN driver_prefix TEXT,
  ADD COLUMN driver_suffix TEXT,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

UPDATE driver_code
SET
  driver_prefix = CASE
    WHEN position('{{USER_CODE}}' IN driver_template) > 0 THEN
      trim(trailing E'\n' FROM substring(
        driver_template
        FROM 1
        FOR position('{{USER_CODE}}' IN driver_template) - 1
      ))
    ELSE ''
  END,
  driver_suffix = CASE
    WHEN position('{{USER_CODE}}' IN driver_template) > 0 THEN
      trim(leading E'\n' FROM substring(
        driver_template
        FROM position('{{USER_CODE}}' IN driver_template) + char_length('{{USER_CODE}}')
      ))
    ELSE ''
  END;

ALTER TABLE driver_code
  DROP COLUMN driver_template,
  ALTER COLUMN driver_prefix SET NOT NULL,
  ALTER COLUMN driver_suffix SET NOT NULL,
  ADD CONSTRAINT driver_code_prefix_suffix_not_null CHECK (
    driver_prefix IS NOT NULL AND driver_suffix IS NOT NULL
  );
