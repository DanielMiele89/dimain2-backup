CREATE SCHEMA [zion]
    AUTHORIZATION [dbo];


GO
GRANT DELETE
    ON SCHEMA::[zion] TO [Analyst];


GO
GRANT INSERT
    ON SCHEMA::[zion] TO [Analyst];


GO
GRANT SELECT
    ON SCHEMA::[zion] TO [Analyst];


GO
GRANT UPDATE
    ON SCHEMA::[zion] TO [Analyst];


GO
GRANT SELECT
    ON SCHEMA::[zion] TO [PII_Removed];

