CREATE SCHEMA [Redemption]
    AUTHORIZATION [dbo];


GO
GRANT DELETE
    ON SCHEMA::[Redemption] TO [Analyst];


GO
GRANT INSERT
    ON SCHEMA::[Redemption] TO [Analyst];


GO
GRANT SELECT
    ON SCHEMA::[Redemption] TO [Analyst];


GO
GRANT UPDATE
    ON SCHEMA::[Redemption] TO [Analyst];


GO
GRANT SELECT
    ON SCHEMA::[Redemption] TO [PII_Removed];

