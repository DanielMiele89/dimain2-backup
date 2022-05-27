CREATE SCHEMA [Derived]
    AUTHORIZATION [dbo];




GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Derived] TO [New_DataOps];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[Derived] TO [New_DataOps];


GO
GRANT UPDATE
    ON SCHEMA::[Derived] TO [New_DataOps];


GO
GRANT SELECT
    ON SCHEMA::[Derived] TO [New_DataOps];


GO
GRANT REFERENCES
    ON SCHEMA::[Derived] TO [New_DataOps];


GO
GRANT INSERT
    ON SCHEMA::[Derived] TO [New_DataOps];


GO
GRANT EXECUTE
    ON SCHEMA::[Derived] TO [New_DataOps];


GO
GRANT DELETE
    ON SCHEMA::[Derived] TO [New_DataOps];


GO
GRANT ALTER
    ON SCHEMA::[Derived] TO [New_DataOps];

