﻿CREATE SCHEMA [DDLMonitor]
    AUTHORIZATION [dbo];




GO
GRANT VIEW DEFINITION
    ON SCHEMA::[DDLMonitor] TO [DataOps];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[DDLMonitor] TO [DataOps];


GO
GRANT UPDATE
    ON SCHEMA::[DDLMonitor] TO [DataOps];


GO
GRANT TAKE OWNERSHIP
    ON SCHEMA::[DDLMonitor] TO [DataOps];


GO
GRANT SELECT
    ON SCHEMA::[DDLMonitor] TO [DataOps];


GO
GRANT REFERENCES
    ON SCHEMA::[DDLMonitor] TO [DataOps];


GO
GRANT INSERT
    ON SCHEMA::[DDLMonitor] TO [DataOps];


GO
GRANT EXECUTE
    ON SCHEMA::[DDLMonitor] TO [DataOps];


GO
GRANT DELETE
    ON SCHEMA::[DDLMonitor] TO [DataOps];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[DDLMonitor] TO [DataOps];


GO
GRANT CONTROL
    ON SCHEMA::[DDLMonitor] TO [DataOps];


GO
GRANT ALTER
    ON SCHEMA::[DDLMonitor] TO [DataOps];

