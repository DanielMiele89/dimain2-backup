CREATE SCHEMA [Stratification]
    AUTHORIZATION [dbo];




GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Stratification] TO [InsightTeam];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Stratification] TO [DataTeam];


GO
GRANT UPDATE
    ON SCHEMA::[Stratification] TO [InsightTeam];


GO
GRANT UPDATE
    ON SCHEMA::[Stratification] TO [DataTeam];


GO
GRANT UPDATE
    ON SCHEMA::[Stratification] TO [DataMart];


GO
GRANT UPDATE
    ON SCHEMA::[Stratification] TO [Analytics];


GO
GRANT SELECT
    ON SCHEMA::[Stratification] TO [InsightTeam];


GO
GRANT SELECT
    ON SCHEMA::[Stratification] TO [DataTeam];


GO
GRANT SELECT
    ON SCHEMA::[Stratification] TO [DataMart];


GO
GRANT SELECT
    ON SCHEMA::[Stratification] TO [Analytics];


GO
GRANT REFERENCES
    ON SCHEMA::[Stratification] TO [InsightTeam];


GO
GRANT REFERENCES
    ON SCHEMA::[Stratification] TO [DataTeam];


GO
GRANT INSERT
    ON SCHEMA::[Stratification] TO [InsightTeam];


GO
GRANT INSERT
    ON SCHEMA::[Stratification] TO [DataTeam];


GO
GRANT INSERT
    ON SCHEMA::[Stratification] TO [DataMart];


GO
GRANT INSERT
    ON SCHEMA::[Stratification] TO [Analytics];


GO
GRANT EXECUTE
    ON SCHEMA::[Stratification] TO [InsightTeam];


GO
GRANT EXECUTE
    ON SCHEMA::[Stratification] TO [DataTeam];


GO
GRANT EXECUTE
    ON SCHEMA::[Stratification] TO [DataMart];


GO
GRANT EXECUTE
    ON SCHEMA::[Stratification] TO [Analytics];


GO
GRANT DELETE
    ON SCHEMA::[Stratification] TO [InsightTeam];


GO
GRANT DELETE
    ON SCHEMA::[Stratification] TO [DataTeam];


GO
GRANT DELETE
    ON SCHEMA::[Stratification] TO [DataMart];


GO
GRANT DELETE
    ON SCHEMA::[Stratification] TO [Analytics];


GO
GRANT ALTER
    ON SCHEMA::[Stratification] TO [InsightTeam];


GO
GRANT ALTER
    ON SCHEMA::[Stratification] TO [DataTeam];


GO
GRANT ALTER
    ON SCHEMA::[Stratification] TO [DataMart];


GO
GRANT ALTER
    ON SCHEMA::[Stratification] TO [Analytics];

