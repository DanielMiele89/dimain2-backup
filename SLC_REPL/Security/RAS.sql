﻿CREATE SCHEMA [RAS]
    AUTHORIZATION [dbo];


GO
GRANT DELETE
    ON SCHEMA::[RAS] TO [Analyst];


GO
GRANT INSERT
    ON SCHEMA::[RAS] TO [Analyst];


GO
GRANT SELECT
    ON SCHEMA::[RAS] TO [Analyst];


GO
GRANT UPDATE
    ON SCHEMA::[RAS] TO [Analyst];


GO
GRANT SELECT
    ON SCHEMA::[RAS] TO [PII_Removed];

