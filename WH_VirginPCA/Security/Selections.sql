CREATE SCHEMA [Selections]
    AUTHORIZATION [New_DataOps];




GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Selections] TO [New_Insight];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Selections] TO [New_DataOps2];


GO
GRANT UPDATE
    ON SCHEMA::[Selections] TO [New_DataOps2];


GO
GRANT TAKE OWNERSHIP
    ON SCHEMA::[Selections] TO [New_DataOps2];


GO
GRANT SELECT
    ON SCHEMA::[Selections] TO [New_Insight];


GO
GRANT SELECT
    ON SCHEMA::[Selections] TO [New_DataOps2];


GO
GRANT INSERT
    ON SCHEMA::[Selections] TO [New_DataOps2];


GO
GRANT EXECUTE
    ON SCHEMA::[Selections] TO [New_DataOps2];


GO
GRANT DELETE
    ON SCHEMA::[Selections] TO [New_DataOps2];


GO
GRANT CONTROL
    ON SCHEMA::[Selections] TO [New_DataOps2];


GO
GRANT ALTER
    ON SCHEMA::[Selections] TO [New_DataOps2];

