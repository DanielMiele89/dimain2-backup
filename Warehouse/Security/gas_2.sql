CREATE SCHEMA [gas]
    AUTHORIZATION [dbo];




GO
GRANT VIEW DEFINITION
    ON SCHEMA::[gas] TO [New_ReadOnly];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[gas] TO [New_PIIRemoved];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[gas] TO [New_OnCall];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[gas] TO [New_Insight];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[gas] TO [New_DataOps];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[gas] TO [New_CampaignOps];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[gas] TO [New_BI];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[gas] TO [DataTeam];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[gas] TO [New_OnCall];


GO
GRANT UPDATE
    ON SCHEMA::[gas] TO [New_OnCall];


GO
GRANT SELECT
    ON SCHEMA::[gas] TO [Stuart];


GO
GRANT SELECT
    ON SCHEMA::[gas] TO [New_ReadOnly];


GO
GRANT SELECT
    ON SCHEMA::[gas] TO [New_PIIRemoved];


GO
GRANT SELECT
    ON SCHEMA::[gas] TO [New_OnCall];


GO
GRANT SELECT
    ON SCHEMA::[gas] TO [New_Insight];


GO
GRANT SELECT
    ON SCHEMA::[gas] TO [New_DataOps];


GO
GRANT SELECT
    ON SCHEMA::[gas] TO [New_CampaignOps];


GO
GRANT SELECT
    ON SCHEMA::[gas] TO [New_BI];


GO
GRANT REFERENCES
    ON SCHEMA::[gas] TO [New_OnCall];


GO
GRANT INSERT
    ON SCHEMA::[gas] TO [New_OnCall];


GO
GRANT INSERT
    ON SCHEMA::[gas] TO [gas];


GO
GRANT EXECUTE
    ON SCHEMA::[gas] TO [New_OnCall];


GO
GRANT EXECUTE
    ON SCHEMA::[gas] TO [gas];


GO
GRANT EXECUTE
    ON SCHEMA::[gas] TO [DataTeam];


GO
GRANT DELETE
    ON SCHEMA::[gas] TO [New_OnCall];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[gas] TO [New_OnCall];


GO
GRANT ALTER
    ON SCHEMA::[gas] TO [New_OnCall];


GO
GRANT ALTER
    ON SCHEMA::[gas] TO [DataTeam];

