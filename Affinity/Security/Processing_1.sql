CREATE SCHEMA [Processing]
    AUTHORIZATION [dbo];




GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Processing] TO [ReadOnly];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Processing] TO [OnCall];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Processing] TO [DataOps];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[Processing] TO [OnCall];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[Processing] TO [DataOps];


GO
GRANT UPDATE
    ON SCHEMA::[Processing] TO [OnCall];


GO
GRANT UPDATE
    ON SCHEMA::[Processing] TO [DataOps];


GO
GRANT TAKE OWNERSHIP
    ON SCHEMA::[Processing] TO [DataOps];


GO
GRANT SELECT
    ON SCHEMA::[Processing] TO [ReadOnly];


GO
GRANT SELECT
    ON SCHEMA::[Processing] TO [OnCall];


GO
GRANT SELECT
    ON SCHEMA::[Processing] TO [DataOps];


GO
GRANT REFERENCES
    ON SCHEMA::[Processing] TO [OnCall];


GO
GRANT REFERENCES
    ON SCHEMA::[Processing] TO [DataOps];


GO
GRANT INSERT
    ON SCHEMA::[Processing] TO [OnCall];


GO
GRANT INSERT
    ON SCHEMA::[Processing] TO [DataOps];


GO
GRANT EXECUTE
    ON SCHEMA::[Processing] TO [OnCall];


GO
GRANT EXECUTE
    ON SCHEMA::[Processing] TO [DataOps];


GO
GRANT DELETE
    ON SCHEMA::[Processing] TO [OnCall];


GO
GRANT DELETE
    ON SCHEMA::[Processing] TO [DataOps];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[Processing] TO [OnCall];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[Processing] TO [DataOps];


GO
GRANT CONTROL
    ON SCHEMA::[Processing] TO [DataOps];


GO
GRANT ALTER
    ON SCHEMA::[Processing] TO [OnCall];


GO
GRANT ALTER
    ON SCHEMA::[Processing] TO [DataOps];

