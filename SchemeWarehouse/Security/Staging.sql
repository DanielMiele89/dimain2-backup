CREATE SCHEMA [Staging]
    AUTHORIZATION [dbo];




GO
GRANT UPDATE
    ON SCHEMA::[Staging] TO [DataMart];


GO
GRANT SELECT
    ON SCHEMA::[Staging] TO [Richard];


GO
GRANT SELECT
    ON SCHEMA::[Staging] TO [Marzena];


GO
GRANT SELECT
    ON SCHEMA::[Staging] TO [gas];


GO
GRANT SELECT
    ON SCHEMA::[Staging] TO [DataMart];


GO
GRANT INSERT
    ON SCHEMA::[Staging] TO [gas];


GO
GRANT INSERT
    ON SCHEMA::[Staging] TO [DataMart];


GO
GRANT EXECUTE
    ON SCHEMA::[Staging] TO [Stuart];


GO
GRANT EXECUTE
    ON SCHEMA::[Staging] TO [gas];


GO
GRANT EXECUTE
    ON SCHEMA::[Staging] TO [DataMart];


GO
GRANT EXECUTE
    ON SCHEMA::[Staging] TO [Analytics];


GO
GRANT DELETE
    ON SCHEMA::[Staging] TO [DataMart];


GO
GRANT ALTER
    ON SCHEMA::[Staging] TO [DataMart];

