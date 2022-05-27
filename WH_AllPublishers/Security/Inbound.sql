CREATE SCHEMA [Inbound]
    AUTHORIZATION [kevinc];




GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Inbound] TO [New_DataOps];


GO
GRANT UPDATE
    ON SCHEMA::[Inbound] TO [New_DataOps];


GO
GRANT SELECT
    ON SCHEMA::[Inbound] TO [New_DataOps];


GO
GRANT INSERT
    ON SCHEMA::[Inbound] TO [New_DataOps];


GO
GRANT EXECUTE
    ON SCHEMA::[Inbound] TO [New_DataOps];


GO
GRANT DELETE
    ON SCHEMA::[Inbound] TO [New_DataOps];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[Inbound] TO [New_DataOps];


GO
GRANT ALTER
    ON SCHEMA::[Inbound] TO [New_DataOps];

