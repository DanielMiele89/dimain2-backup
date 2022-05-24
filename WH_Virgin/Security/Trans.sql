CREATE SCHEMA [Trans]
    AUTHORIZATION [dbo];




GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Trans] TO [New_Insight];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Trans] TO [New_DataOps];


GO
GRANT SELECT
    ON SCHEMA::[Trans] TO [virgin_etl_user];


GO
GRANT SELECT
    ON SCHEMA::[Trans] TO [New_Insight];


GO
GRANT SELECT
    ON SCHEMA::[Trans] TO [New_DataOps];

