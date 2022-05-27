CREATE SCHEMA [Tableau]
    AUTHORIZATION [dbo];




GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Tableau] TO [New_PIIRemoved];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Tableau] TO [New_Insight];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Tableau] TO [New_DataOps];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[Tableau] TO [New_DataOps];


GO
GRANT UPDATE
    ON SCHEMA::[Tableau] TO [New_DataOps];


GO
GRANT TAKE OWNERSHIP
    ON SCHEMA::[Tableau] TO [New_DataOps];


GO
GRANT SELECT
    ON SCHEMA::[Tableau] TO [Tony];


GO
GRANT SELECT
    ON SCHEMA::[Tableau] TO [New_PIIRemoved];


GO
GRANT SELECT
    ON SCHEMA::[Tableau] TO [New_Insight];


GO
GRANT SELECT
    ON SCHEMA::[Tableau] TO [New_DataOps];


GO
GRANT REFERENCES
    ON SCHEMA::[Tableau] TO [New_DataOps];


GO
GRANT INSERT
    ON SCHEMA::[Tableau] TO [New_DataOps];


GO
GRANT INSERT
    ON SCHEMA::[Tableau] TO [gas];


GO
GRANT EXECUTE
    ON SCHEMA::[Tableau] TO [New_DataOps];


GO
GRANT DELETE
    ON SCHEMA::[Tableau] TO [New_DataOps];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[Tableau] TO [New_DataOps];


GO
GRANT CONTROL
    ON SCHEMA::[Tableau] TO [New_DataOps];


GO
GRANT ALTER
    ON SCHEMA::[Tableau] TO [New_DataOps];

