CREATE SCHEMA [Lion]
    AUTHORIZATION [dbo];




GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Lion] TO [New_ReadOnly];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Lion] TO [New_PIIRemoved];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Lion] TO [New_OnCall];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Lion] TO [New_Insight];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Lion] TO [New_DataOps];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Lion] TO [New_CampaignOps];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Lion] TO [New_BI];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Lion] TO [DataTeam];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Lion] TO [CampaignExecutionUser];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[Lion] TO [New_OnCall];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[Lion] TO [New_CampaignOps];


GO
GRANT UPDATE
    ON SCHEMA::[Lion] TO [Zoe];


GO
GRANT UPDATE
    ON SCHEMA::[Lion] TO [Stuart];


GO
GRANT UPDATE
    ON SCHEMA::[Lion] TO [New_OnCall];


GO
GRANT UPDATE
    ON SCHEMA::[Lion] TO [New_CampaignOps];


GO
GRANT UPDATE
    ON SCHEMA::[Lion] TO [DataTeam];


GO
GRANT UPDATE
    ON SCHEMA::[Lion] TO [DataMart];


GO
GRANT UPDATE
    ON SCHEMA::[Lion] TO [CampaignExecutionUser];


GO
GRANT TAKE OWNERSHIP
    ON SCHEMA::[Lion] TO [New_CampaignOps];


GO
GRANT SELECT
    ON SCHEMA::[Lion] TO [Zoe];


GO
GRANT SELECT
    ON SCHEMA::[Lion] TO [Stuart];


GO
GRANT SELECT
    ON SCHEMA::[Lion] TO [New_ReadOnly];


GO
GRANT SELECT
    ON SCHEMA::[Lion] TO [New_PIIRemoved];


GO
GRANT SELECT
    ON SCHEMA::[Lion] TO [New_OnCall];


GO
GRANT SELECT
    ON SCHEMA::[Lion] TO [New_Insight];


GO
GRANT SELECT
    ON SCHEMA::[Lion] TO [New_DataOps];


GO
GRANT SELECT
    ON SCHEMA::[Lion] TO [New_CampaignOps];


GO
GRANT SELECT
    ON SCHEMA::[Lion] TO [New_BI];


GO
GRANT SELECT
    ON SCHEMA::[Lion] TO [DataTeam];


GO
GRANT SELECT
    ON SCHEMA::[Lion] TO [DataMart];


GO
GRANT SELECT
    ON SCHEMA::[Lion] TO [CampaignExecutionUser];


GO
GRANT REFERENCES
    ON SCHEMA::[Lion] TO [New_OnCall];


GO
GRANT REFERENCES
    ON SCHEMA::[Lion] TO [New_CampaignOps];


GO
GRANT REFERENCES
    ON SCHEMA::[Lion] TO [CampaignExecutionUser];


GO
GRANT INSERT
    ON SCHEMA::[Lion] TO [Zoe];


GO
GRANT INSERT
    ON SCHEMA::[Lion] TO [Stuart];


GO
GRANT INSERT
    ON SCHEMA::[Lion] TO [New_OnCall];


GO
GRANT INSERT
    ON SCHEMA::[Lion] TO [New_CampaignOps];


GO
GRANT INSERT
    ON SCHEMA::[Lion] TO [DataTeam];


GO
GRANT INSERT
    ON SCHEMA::[Lion] TO [DataMart];


GO
GRANT INSERT
    ON SCHEMA::[Lion] TO [CampaignExecutionUser];


GO
GRANT EXECUTE
    ON SCHEMA::[Lion] TO [New_OnCall];


GO
GRANT EXECUTE
    ON SCHEMA::[Lion] TO [New_CampaignOps];


GO
GRANT EXECUTE
    ON SCHEMA::[Lion] TO [DataTeam];


GO
GRANT EXECUTE
    ON SCHEMA::[Lion] TO [CampaignExecutionUser];


GO
GRANT DELETE
    ON SCHEMA::[Lion] TO [Zoe];


GO
GRANT DELETE
    ON SCHEMA::[Lion] TO [Stuart];


GO
GRANT DELETE
    ON SCHEMA::[Lion] TO [New_OnCall];


GO
GRANT DELETE
    ON SCHEMA::[Lion] TO [New_CampaignOps];


GO
GRANT DELETE
    ON SCHEMA::[Lion] TO [DataTeam];


GO
GRANT DELETE
    ON SCHEMA::[Lion] TO [DataMart];


GO
GRANT DELETE
    ON SCHEMA::[Lion] TO [CampaignExecutionUser];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[Lion] TO [New_OnCall];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[Lion] TO [New_CampaignOps];


GO
GRANT CONTROL
    ON SCHEMA::[Lion] TO [New_CampaignOps];


GO
GRANT ALTER
    ON SCHEMA::[Lion] TO [Zoe];


GO
GRANT ALTER
    ON SCHEMA::[Lion] TO [Stuart];


GO
GRANT ALTER
    ON SCHEMA::[Lion] TO [New_OnCall];


GO
GRANT ALTER
    ON SCHEMA::[Lion] TO [New_CampaignOps];


GO
GRANT ALTER
    ON SCHEMA::[Lion] TO [CampaignExecutionUser];

