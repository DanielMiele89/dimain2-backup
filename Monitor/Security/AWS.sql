﻿CREATE SCHEMA [AWS]
    AUTHORIZATION [dbo];




GO
GRANT UPDATE
    ON SCHEMA::[AWS] TO [CRTImport];


GO
GRANT SELECT
    ON SCHEMA::[AWS] TO [CRTImport];


GO
GRANT INSERT
    ON SCHEMA::[AWS] TO [CRTImport];


GO
GRANT EXECUTE
    ON SCHEMA::[AWS] TO [CRTImport];


GO
GRANT DELETE
    ON SCHEMA::[AWS] TO [CRTImport];
