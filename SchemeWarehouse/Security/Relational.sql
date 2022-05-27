CREATE SCHEMA [Relational]
    AUTHORIZATION [dbo];




GO
GRANT UPDATE
    ON SCHEMA::[Relational] TO [gas];


GO
GRANT UPDATE
    ON SCHEMA::[Relational] TO [DataMart];


GO
GRANT SELECT
    ON SCHEMA::[Relational] TO [gas];


GO
GRANT SELECT
    ON SCHEMA::[Relational] TO [DataMart];


GO
GRANT SELECT
    ON SCHEMA::[Relational] TO [Analytics];


GO
GRANT INSERT
    ON SCHEMA::[Relational] TO [gas];


GO
GRANT INSERT
    ON SCHEMA::[Relational] TO [DataMart];


GO
GRANT EXECUTE
    ON SCHEMA::[Relational] TO [gas];


GO
GRANT EXECUTE
    ON SCHEMA::[Relational] TO [DataMart];


GO
GRANT EXECUTE
    ON SCHEMA::[Relational] TO [Analytics];


GO
GRANT DELETE
    ON SCHEMA::[Relational] TO [DataMart];


GO
GRANT ALTER
    ON SCHEMA::[Relational] TO [DataMart];

