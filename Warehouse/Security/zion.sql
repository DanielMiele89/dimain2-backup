CREATE SCHEMA [zion]
    AUTHORIZATION [dbo];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[zion] TO [New_PIIRemoved];


GO
GRANT SELECT
    ON SCHEMA::[zion] TO [New_PIIRemoved];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[zion] TO [New_ReadOnly];


GO
GRANT SELECT
    ON SCHEMA::[zion] TO [New_ReadOnly];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[zion] TO [New_OnCall];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[zion] TO [New_OnCall];


GO
GRANT UPDATE
    ON SCHEMA::[zion] TO [New_OnCall];


GO
GRANT SELECT
    ON SCHEMA::[zion] TO [New_OnCall];


GO
GRANT REFERENCES
    ON SCHEMA::[zion] TO [New_OnCall];


GO
GRANT INSERT
    ON SCHEMA::[zion] TO [New_OnCall];


GO
GRANT EXECUTE
    ON SCHEMA::[zion] TO [New_OnCall];


GO
GRANT DELETE
    ON SCHEMA::[zion] TO [New_OnCall];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[zion] TO [New_OnCall];


GO
GRANT ALTER
    ON SCHEMA::[zion] TO [New_OnCall];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[zion] TO [New_BI];


GO
GRANT SELECT
    ON SCHEMA::[zion] TO [New_BI];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[zion] TO [New_CampaignOps];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[zion] TO [New_CampaignOps];


GO
GRANT UPDATE
    ON SCHEMA::[zion] TO [New_CampaignOps];


GO
GRANT TAKE OWNERSHIP
    ON SCHEMA::[zion] TO [New_CampaignOps];


GO
GRANT SELECT
    ON SCHEMA::[zion] TO [New_CampaignOps];


GO
GRANT REFERENCES
    ON SCHEMA::[zion] TO [New_CampaignOps];


GO
GRANT INSERT
    ON SCHEMA::[zion] TO [New_CampaignOps];


GO
GRANT EXECUTE
    ON SCHEMA::[zion] TO [New_CampaignOps];


GO
GRANT DELETE
    ON SCHEMA::[zion] TO [New_CampaignOps];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[zion] TO [New_CampaignOps];


GO
GRANT CONTROL
    ON SCHEMA::[zion] TO [New_CampaignOps];


GO
GRANT ALTER
    ON SCHEMA::[zion] TO [New_CampaignOps];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[zion] TO [New_DataOps];


GO
GRANT SELECT
    ON SCHEMA::[zion] TO [New_DataOps];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[zion] TO [New_Insight];


GO
GRANT SELECT
    ON SCHEMA::[zion] TO [New_Insight];


GO
GRANT SELECT
    ON SCHEMA::[zion] TO [InsightTeam];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[zion] TO [DataTeam];


GO
GRANT UPDATE
    ON SCHEMA::[zion] TO [DataTeam];


GO
GRANT SELECT
    ON SCHEMA::[zion] TO [DataTeam];


GO
GRANT INSERT
    ON SCHEMA::[zion] TO [DataTeam];


GO
GRANT EXECUTE
    ON SCHEMA::[zion] TO [DataTeam];


GO
GRANT DELETE
    ON SCHEMA::[zion] TO [DataTeam];

