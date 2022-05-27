CREATE SCHEMA [iron]
    AUTHORIZATION [dbo];




GO
GRANT VIEW DEFINITION
    ON SCHEMA::[iron] TO [New_ReadOnly];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[iron] TO [New_PIIRemoved];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[iron] TO [New_OnCall];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[iron] TO [New_Insight];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[iron] TO [New_DataOps];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[iron] TO [New_CampaignOps];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[iron] TO [New_BI];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[iron] TO [DataTeam];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[iron] TO [CampaignExecutionUser];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[iron] TO [New_OnCall];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[iron] TO [New_CampaignOps];


GO
GRANT UPDATE
    ON SCHEMA::[iron] TO [New_OnCall];


GO
GRANT UPDATE
    ON SCHEMA::[iron] TO [New_CampaignOps];


GO
GRANT UPDATE
    ON SCHEMA::[iron] TO [DataTeam];


GO
GRANT UPDATE
    ON SCHEMA::[iron] TO [CampaignExecutionUser];


GO
GRANT TAKE OWNERSHIP
    ON SCHEMA::[iron] TO [New_CampaignOps];


GO
GRANT SELECT
    ON SCHEMA::[iron] TO [New_ReadOnly];


GO
GRANT SELECT
    ON SCHEMA::[iron] TO [New_PIIRemoved];


GO
GRANT SELECT
    ON SCHEMA::[iron] TO [New_OnCall];


GO
GRANT SELECT
    ON SCHEMA::[iron] TO [New_Insight];


GO
GRANT SELECT
    ON SCHEMA::[iron] TO [New_DataOps];


GO
GRANT SELECT
    ON SCHEMA::[iron] TO [New_CampaignOps];


GO
GRANT SELECT
    ON SCHEMA::[iron] TO [New_BI];


GO
GRANT SELECT
    ON SCHEMA::[iron] TO [Ed];


GO
GRANT SELECT
    ON SCHEMA::[iron] TO [DataTeam];


GO
GRANT SELECT
    ON SCHEMA::[iron] TO [CampaignExecutionUser];


GO
GRANT REFERENCES
    ON SCHEMA::[iron] TO [New_OnCall];


GO
GRANT REFERENCES
    ON SCHEMA::[iron] TO [New_CampaignOps];


GO
GRANT REFERENCES
    ON SCHEMA::[iron] TO [CampaignExecutionUser];


GO
GRANT INSERT
    ON SCHEMA::[iron] TO [New_OnCall];


GO
GRANT INSERT
    ON SCHEMA::[iron] TO [New_CampaignOps];


GO
GRANT INSERT
    ON SCHEMA::[iron] TO [DataTeam];


GO
GRANT INSERT
    ON SCHEMA::[iron] TO [CampaignExecutionUser];


GO
GRANT EXECUTE
    ON SCHEMA::[iron] TO [New_OnCall];


GO
GRANT EXECUTE
    ON SCHEMA::[iron] TO [New_CampaignOps];


GO
GRANT EXECUTE
    ON SCHEMA::[iron] TO [DataTeam];


GO
GRANT EXECUTE
    ON SCHEMA::[iron] TO [CampaignExecutionUser];


GO
GRANT DELETE
    ON SCHEMA::[iron] TO [New_OnCall];


GO
GRANT DELETE
    ON SCHEMA::[iron] TO [New_CampaignOps];


GO
GRANT DELETE
    ON SCHEMA::[iron] TO [DataTeam];


GO
GRANT DELETE
    ON SCHEMA::[iron] TO [CampaignExecutionUser];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[iron] TO [New_OnCall];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[iron] TO [New_CampaignOps];


GO
GRANT CONTROL
    ON SCHEMA::[iron] TO [New_CampaignOps];


GO
GRANT ALTER
    ON SCHEMA::[iron] TO [New_OnCall];


GO
GRANT ALTER
    ON SCHEMA::[iron] TO [New_CampaignOps];


GO
GRANT ALTER
    ON SCHEMA::[iron] TO [CampaignExecutionUser];

