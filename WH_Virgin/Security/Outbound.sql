CREATE SCHEMA [Outbound]
    AUTHORIZATION [dbo];




GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Outbound] TO [virgin_prod];


GO
GRANT UPDATE
    ON SCHEMA::[Outbound] TO [crtimport];


GO
GRANT SELECT
    ON SCHEMA::[Outbound] TO [virgin_prod];


GO
GRANT SELECT
    ON SCHEMA::[Outbound] TO [crtimport];


GO
GRANT INSERT
    ON SCHEMA::[Outbound] TO [crtimport];

