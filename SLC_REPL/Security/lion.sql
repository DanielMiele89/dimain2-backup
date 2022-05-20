CREATE SCHEMA [lion]
    AUTHORIZATION [dbo];


GO
GRANT DELETE
    ON SCHEMA::[lion] TO [Analyst];


GO
GRANT INSERT
    ON SCHEMA::[lion] TO [Analyst];


GO
GRANT SELECT
    ON SCHEMA::[lion] TO [Analyst];


GO
GRANT UPDATE
    ON SCHEMA::[lion] TO [Analyst];


GO
GRANT SELECT
    ON SCHEMA::[lion] TO [PII_Removed];

