CREATE SCHEMA [Derived]
    AUTHORIZATION [New_DataOps];




GO



GO



GO



GO



GO



GO



GO



GO



GO



GO



GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Derived] TO [New_Insight];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Derived] TO [New_DataOps2];


GO
GRANT UPDATE
    ON SCHEMA::[Derived] TO [New_DataOps2];


GO
GRANT TAKE OWNERSHIP
    ON SCHEMA::[Derived] TO [New_DataOps2];


GO
GRANT SELECT
    ON SCHEMA::[Derived] TO [New_Insight];


GO
GRANT SELECT
    ON SCHEMA::[Derived] TO [New_DataOps2];


GO
GRANT INSERT
    ON SCHEMA::[Derived] TO [New_DataOps2];


GO
GRANT EXECUTE
    ON SCHEMA::[Derived] TO [New_DataOps2];


GO
GRANT DELETE
    ON SCHEMA::[Derived] TO [New_DataOps2];


GO
GRANT CONTROL
    ON SCHEMA::[Derived] TO [New_DataOps2];


GO
GRANT ALTER
    ON SCHEMA::[Derived] TO [New_DataOps2];

