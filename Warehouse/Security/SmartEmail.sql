CREATE SCHEMA [SmartEmail]
    AUTHORIZATION [dbo];




GO
GRANT VIEW DEFINITION
    ON SCHEMA::[SmartEmail] TO [New_ReadOnly];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[SmartEmail] TO [New_PIIRemoved];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[SmartEmail] TO [New_OnCall];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[SmartEmail] TO [New_Insight];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[SmartEmail] TO [New_DataOps];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[SmartEmail] TO [New_CampaignOps];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[SmartEmail] TO [New_BI];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[SmartEmail] TO [New_OnCall];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[SmartEmail] TO [New_CampaignOps];


GO
GRANT UPDATE
    ON SCHEMA::[SmartEmail] TO [New_OnCall];


GO
GRANT UPDATE
    ON SCHEMA::[SmartEmail] TO [New_DataOps];


GO
GRANT UPDATE
    ON SCHEMA::[SmartEmail] TO [New_CampaignOps];


GO
GRANT TAKE OWNERSHIP
    ON SCHEMA::[SmartEmail] TO [New_CampaignOps];


GO
GRANT SELECT
    ON SCHEMA::[SmartEmail] TO [New_ReadOnly];


GO
GRANT SELECT
    ON SCHEMA::[SmartEmail] TO [New_OnCall];


GO
GRANT SELECT
    ON SCHEMA::[SmartEmail] TO [New_Insight];


GO
GRANT SELECT
    ON SCHEMA::[SmartEmail] TO [New_DataOps];


GO
GRANT SELECT
    ON SCHEMA::[SmartEmail] TO [New_CampaignOps];


GO
GRANT SELECT
    ON SCHEMA::[SmartEmail] TO [New_BI];


GO
GRANT REFERENCES
    ON SCHEMA::[SmartEmail] TO [New_OnCall];


GO
GRANT REFERENCES
    ON SCHEMA::[SmartEmail] TO [New_CampaignOps];


GO
GRANT INSERT
    ON SCHEMA::[SmartEmail] TO [New_OnCall];


GO
GRANT INSERT
    ON SCHEMA::[SmartEmail] TO [New_DataOps];


GO
GRANT INSERT
    ON SCHEMA::[SmartEmail] TO [New_CampaignOps];


GO
GRANT EXECUTE
    ON SCHEMA::[SmartEmail] TO [sfduser];


GO
GRANT EXECUTE
    ON SCHEMA::[SmartEmail] TO [New_OnCall];


GO
GRANT EXECUTE
    ON SCHEMA::[SmartEmail] TO [New_DataOps];


GO
GRANT EXECUTE
    ON SCHEMA::[SmartEmail] TO [New_CampaignOps];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[SmartEmail] TO [New_OnCall];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[SmartEmail] TO [New_CampaignOps];


GO
GRANT CONTROL
    ON SCHEMA::[SmartEmail] TO [New_CampaignOps];


GO
GRANT ALTER
    ON SCHEMA::[SmartEmail] TO [New_OnCall];


GO
GRANT ALTER
    ON SCHEMA::[SmartEmail] TO [New_DataOps];


GO
GRANT ALTER
    ON SCHEMA::[SmartEmail] TO [New_CampaignOps];


GO
GRANT DELETE
    ON SCHEMA::[SmartEmail] TO [New_CampaignOps];


GO
GRANT DELETE
    ON SCHEMA::[SmartEmail] TO [New_OnCall];

