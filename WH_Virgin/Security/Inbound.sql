CREATE SCHEMA [Inbound]
    AUTHORIZATION [dbo];




GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Inbound] TO [virgin_prod];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Inbound] TO [New_DataOps];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Inbound] TO [crtimport];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[Inbound] TO [crtimport];


GO
GRANT UPDATE
    ON SCHEMA::[Inbound] TO [crtimport];


GO
GRANT TAKE OWNERSHIP
    ON SCHEMA::[Inbound] TO [crtimport];


GO
GRANT SELECT
    ON SCHEMA::[Inbound] TO [virgin_prod];


GO
GRANT SELECT
    ON SCHEMA::[Inbound] TO [New_DataOps];


GO
GRANT SELECT
    ON SCHEMA::[Inbound] TO [crtimport];


GO
GRANT REFERENCES
    ON SCHEMA::[Inbound] TO [crtimport];


GO
GRANT INSERT
    ON SCHEMA::[Inbound] TO [virgin_prod];


GO
GRANT INSERT
    ON SCHEMA::[Inbound] TO [crtimport];


GO
GRANT EXECUTE
    ON SCHEMA::[Inbound] TO [crtimport];


GO
GRANT DELETE
    ON SCHEMA::[Inbound] TO [crtimport];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[Inbound] TO [crtimport];


GO
GRANT CONTROL
    ON SCHEMA::[Inbound] TO [crtimport];


GO
GRANT ALTER
    ON SCHEMA::[Inbound] TO [crtimport];

