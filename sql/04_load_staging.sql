Server [localhost]: localhost
Database [postgres]: fraud_analytics
Port [5432]: 5432
Username [postgres]: postgres
Password for user postgres:

psql (17.7)
WARNING: Console code page (437) differs from Windows code page (1252)
         8-bit characters might not work correctly. See psql reference
         page "Notes for Windows users" for details.
Type "help" for help.

fraud_analytics=# \copy staging.pros_transaction FROM 'D:/Innomatics/Git_Uploads/Credit-card-risk-analytics/data/processed/pros_transaction.csv' WITH (FORMAT csv, HEADER true, NULL '');
COPY 590540
fraud_analytics=# \copy staging.pros_identity FROM 'D:/Innomatics/Git_Uploads/Credit-card-risk-analytics/data/processed/pros_identity.csv' WITH (FORMAT csv, HEADER true, NULL '');
COPY 144233