-- ============================================================
-- Turns on MySQL's slow query log (D7: logging)
-- Run ONCE as root in the MySQL Command Line Client.
-- A "slow query" is any query that takes longer than 1 second.
-- SET PERSIST keeps the setting after MySQL restarts.
-- ============================================================
SET PERSIST slow_query_log = 'ON';
SET PERSIST long_query_time = 1;
SET PERSIST log_slow_admin_statements = 'ON';

-- Where the log file is, and whether it is on:
-- (the @@global values are what new connections will use)
SELECT @@global.slow_query_log AS Slow_query_log_on,
       @@global.long_query_time AS Seconds_before_a_query_counts_as_slow,
       @@global.slow_query_log_file AS Log_file;
