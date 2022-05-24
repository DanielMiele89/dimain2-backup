CREATE SCHEMA [Staging]
    AUTHORIZATION [dbo];




GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Staging] TO [New_ReadOnly];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Staging] TO [New_OnCall];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Staging] TO [New_Insight];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Staging] TO [New_DataOps];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Staging] TO [New_CampaignOps];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Staging] TO [New_BI];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[Staging] TO [New_OnCall];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[Staging] TO [New_DataOps];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[Staging] TO [New_CampaignOps];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[Staging] TO [New_BI];


GO
GRANT UPDATE
    ON SCHEMA::[Staging] TO [New_OnCall];


GO
GRANT UPDATE
    ON SCHEMA::[Staging] TO [New_DataOps];


GO
GRANT UPDATE
    ON SCHEMA::[Staging] TO [New_CampaignOps];


GO
GRANT UPDATE
    ON SCHEMA::[Staging] TO [New_BI];


GO
GRANT TAKE OWNERSHIP
    ON SCHEMA::[Staging] TO [New_CampaignOps];


GO
GRANT SELECT
    ON SCHEMA::[Staging] TO [New_ReadOnly];


GO
GRANT SELECT
    ON SCHEMA::[Staging] TO [New_OnCall];


GO
GRANT SELECT
    ON SCHEMA::[Staging] TO [New_DataOps];


GO
GRANT SELECT
    ON SCHEMA::[Staging] TO [New_CampaignOps];


GO
GRANT SELECT
    ON SCHEMA::[Staging] TO [New_BI];


GO
GRANT REFERENCES
    ON SCHEMA::[Staging] TO [New_OnCall];


GO
GRANT REFERENCES
    ON SCHEMA::[Staging] TO [New_DataOps];


GO
GRANT REFERENCES
    ON SCHEMA::[Staging] TO [New_CampaignOps];


GO
GRANT REFERENCES
    ON SCHEMA::[Staging] TO [New_BI];


GO
GRANT INSERT
    ON SCHEMA::[Staging] TO [New_OnCall];


GO
GRANT INSERT
    ON SCHEMA::[Staging] TO [New_DataOps];


GO
GRANT INSERT
    ON SCHEMA::[Staging] TO [New_CampaignOps];


GO
GRANT INSERT
    ON SCHEMA::[Staging] TO [New_BI];


GO
GRANT EXECUTE
    ON SCHEMA::[Staging] TO [New_OnCall];


GO
GRANT EXECUTE
    ON SCHEMA::[Staging] TO [New_DataOps];


GO
GRANT EXECUTE
    ON SCHEMA::[Staging] TO [New_CampaignOps];


GO
GRANT EXECUTE
    ON SCHEMA::[Staging] TO [New_BI];


GO
GRANT DELETE
    ON SCHEMA::[Staging] TO [New_OnCall];


GO
GRANT DELETE
    ON SCHEMA::[Staging] TO [New_DataOps];


GO
GRANT DELETE
    ON SCHEMA::[Staging] TO [New_CampaignOps];


GO
GRANT DELETE
    ON SCHEMA::[Staging] TO [New_BI];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[Staging] TO [New_OnCall];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[Staging] TO [New_CampaignOps];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[Staging] TO [New_BI];


GO
GRANT CONTROL
    ON SCHEMA::[Staging] TO [New_CampaignOps];


GO
GRANT ALTER
    ON SCHEMA::[Staging] TO [New_OnCall];


GO
GRANT ALTER
    ON SCHEMA::[Staging] TO [New_DataOps];


GO
GRANT ALTER
    ON SCHEMA::[Staging] TO [New_CampaignOps];


GO
GRANT ALTER
    ON SCHEMA::[Staging] TO [New_BI];


GO
DENY SELECT
    ON SCHEMA::[Staging] TO [New_Insight];

