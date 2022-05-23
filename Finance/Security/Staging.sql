CREATE SCHEMA [Staging]
    AUTHORIZATION [dbo];


GO
GRANT ALTER
    ON SCHEMA::[Staging] TO [DataOps];


GO
GRANT CONTROL
    ON SCHEMA::[Staging] TO [DataOps];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[Staging] TO [DataOps];


GO
GRANT DELETE
    ON SCHEMA::[Staging] TO [DataOps];


GO
GRANT EXECUTE
    ON SCHEMA::[Staging] TO [DataOps];


GO
GRANT INSERT
    ON SCHEMA::[Staging] TO [DataOps];


GO
GRANT REFERENCES
    ON SCHEMA::[Staging] TO [DataOps];


GO
GRANT SELECT
    ON SCHEMA::[Staging] TO [DataOps];


GO
GRANT TAKE OWNERSHIP
    ON SCHEMA::[Staging] TO [DataOps];


GO
GRANT UPDATE
    ON SCHEMA::[Staging] TO [DataOps];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Staging] TO [DataOps];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[Staging] TO [DataOps];

