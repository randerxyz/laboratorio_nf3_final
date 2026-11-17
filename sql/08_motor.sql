SELECT @@innodb_buffer_pool_size,@@innodb_flush_log_at_trx_commit,@@sync_binlog;
SHOW GLOBAL STATUS LIKE 'Innodb_buffer_pool_read%';
SHOW GLOBAL STATUS LIKE 'Innodb_buffer_pool_pages%';
SHOW ENGINE INNODB STATUS;
SHOW BINARY LOGS;
-- Exige privilégios administrativos e configuração do servidor.
SELECT ENGINE,ENGINE_LOCK_ID,OBJECT_SCHEMA,OBJECT_NAME,INDEX_NAME,LOCK_TYPE,LOCK_MODE,LOCK_STATUS
 FROM performance_schema.data_locks WHERE OBJECT_SCHEMA IN ('nf3_lab','loja_cerrado');
SELECT * FROM performance_schema.data_lock_waits;
