CREATE SCHEMA [Staging]
    AUTHORIZATION [dbo];




GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Staging] TO [New_DataOps];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[Staging] TO [New_DataOps];


GO
GRANT UPDATE
    ON SCHEMA::[Staging] TO [New_DataOps];


GO
GRANT UPDATE
    ON SCHEMA::[Staging] TO [conord];


GO
GRANT SELECT
    ON SCHEMA::[Staging] TO [New_Insight];


GO
GRANT SELECT
    ON SCHEMA::[Staging] TO [New_DataOps];


GO
GRANT SELECT
    ON SCHEMA::[Staging] TO [conord];


GO
GRANT REFERENCES
    ON SCHEMA::[Staging] TO [New_DataOps];


GO
GRANT INSERT
    ON SCHEMA::[Staging] TO [New_DataOps];


GO
GRANT INSERT
    ON SCHEMA::[Staging] TO [conord];


GO
GRANT EXECUTE
    ON SCHEMA::[Staging] TO [New_DataOps];


GO
GRANT DELETE
    ON SCHEMA::[Staging] TO [New_DataOps];


GO
GRANT DELETE
    ON SCHEMA::[Staging] TO [conord];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[Staging] TO [New_DataOps];


GO
GRANT ALTER
    ON SCHEMA::[Staging] TO [New_DataOps];


GO
GRANT ALTER
    ON SCHEMA::[Staging] TO [conord];

