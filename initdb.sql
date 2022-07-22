%{ for database in databases }
SELECT 'CREATE DATABASE ${database.name} WITH LC_COLLATE ''C'' LC_CTYPE ''C'' TEMPLATE template0'
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${database.name}')\gexec
    \connect ${database.name};
SELECT 'CREATE USER ${database.username} WITH ENCRYPTED PASSWORD ''${database.password}'''
    WHERE NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${database.username}')\gexec
GRANT ${database.username} TO ${root_username};
GRANT ALL PRIVILEGES ON DATABASE ${database.name} TO ${database.username};
GRANT ALL ON ALL TABLES IN SCHEMA public TO ${database.username};
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO ${database.username};
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO ${database.username};
ALTER USER ${database.username} WITH ENCRYPTED PASSWORD '${database.password}';
%{ endfor ~}