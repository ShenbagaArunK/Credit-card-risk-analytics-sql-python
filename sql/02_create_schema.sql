create schema if not exists staging;

SELECT schema_name FROM information_schema.schemata
WHERE schema_name IN ('public', 'staging');