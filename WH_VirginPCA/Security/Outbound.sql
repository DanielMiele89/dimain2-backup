CREATE SCHEMA [Outbound]
    AUTHORIZATION [New_DataOps];




GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Outbound] TO [visa_prod];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Outbound] TO [virgin_prod];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Outbound] TO [New_DataOps2];


GO
GRANT UPDATE
    ON SCHEMA::[Outbound] TO [New_DataOps2];


GO
GRANT TAKE OWNERSHIP
    ON SCHEMA::[Outbound] TO [New_DataOps2];


GO
GRANT SELECT
    ON SCHEMA::[Outbound] TO [visa_prod];


GO
GRANT SELECT
    ON SCHEMA::[Outbound] TO [virgin_prod];


GO
GRANT SELECT
    ON SCHEMA::[Outbound] TO [New_DataOps2];


GO
GRANT INSERT
    ON SCHEMA::[Outbound] TO [New_DataOps2];


GO
GRANT EXECUTE
    ON SCHEMA::[Outbound] TO [New_DataOps2];


GO
GRANT DELETE
    ON SCHEMA::[Outbound] TO [New_DataOps2];


GO
GRANT CONTROL
    ON SCHEMA::[Outbound] TO [New_DataOps2];


GO
GRANT ALTER
    ON SCHEMA::[Outbound] TO [New_DataOps2];

