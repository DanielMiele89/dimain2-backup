CREATE SCHEMA [internal]
    AUTHORIZATION [dbo];




GO
GRANT UPDATE
    ON SCHEMA::[internal] TO [AllSchemaOwner];


GO
GRANT SELECT
    ON SCHEMA::[internal] TO [AllSchemaOwner];


GO
GRANT INSERT
    ON SCHEMA::[internal] TO [AllSchemaOwner];


GO
GRANT EXECUTE
    ON SCHEMA::[internal] TO [AllSchemaOwner];


GO
GRANT DELETE
    ON SCHEMA::[internal] TO [AllSchemaOwner];

