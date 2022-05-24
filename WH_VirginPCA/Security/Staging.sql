CREATE SCHEMA [Staging]
    AUTHORIZATION [New_DataOps];




GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Staging] TO [New_Insight];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Staging] TO [New_DataOps2];


GO
GRANT UPDATE
    ON SCHEMA::[Staging] TO [New_DataOps2];


GO
GRANT TAKE OWNERSHIP
    ON SCHEMA::[Staging] TO [New_DataOps2];


GO
GRANT SELECT
    ON SCHEMA::[Staging] TO [New_Insight];


GO
GRANT SELECT
    ON SCHEMA::[Staging] TO [New_DataOps2];


GO
GRANT INSERT
    ON SCHEMA::[Staging] TO [New_DataOps2];


GO
GRANT EXECUTE
    ON SCHEMA::[Staging] TO [New_DataOps2];


GO
GRANT DELETE
    ON SCHEMA::[Staging] TO [New_DataOps2];


GO
GRANT CONTROL
    ON SCHEMA::[Staging] TO [New_DataOps2];


GO
GRANT ALTER
    ON SCHEMA::[Staging] TO [New_DataOps2];

