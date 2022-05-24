CREATE SCHEMA [Inbound]
    AUTHORIZATION [New_DataOps];




GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Inbound] TO [visa_prod];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Inbound] TO [virgin_prod];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Inbound] TO [New_DataOps2];


GO
GRANT UPDATE
    ON SCHEMA::[Inbound] TO [New_DataOps2];


GO
GRANT TAKE OWNERSHIP
    ON SCHEMA::[Inbound] TO [New_DataOps2];


GO
GRANT SELECT
    ON SCHEMA::[Inbound] TO [visa_prod];


GO
GRANT SELECT
    ON SCHEMA::[Inbound] TO [virgin_prod];


GO
GRANT SELECT
    ON SCHEMA::[Inbound] TO [New_DataOps2];


GO
GRANT INSERT
    ON SCHEMA::[Inbound] TO [visa_prod];


GO
GRANT INSERT
    ON SCHEMA::[Inbound] TO [virgin_prod];


GO
GRANT INSERT
    ON SCHEMA::[Inbound] TO [New_DataOps2];


GO
GRANT EXECUTE
    ON SCHEMA::[Inbound] TO [New_DataOps2];


GO
GRANT DELETE
    ON SCHEMA::[Inbound] TO [New_DataOps2];


GO
GRANT CONTROL
    ON SCHEMA::[Inbound] TO [New_DataOps2];


GO
GRANT ALTER
    ON SCHEMA::[Inbound] TO [New_DataOps2];

