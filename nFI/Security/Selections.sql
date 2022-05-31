CREATE SCHEMA [Selections]
    AUTHORIZATION [dbo];


GO
GRANT EXECUTE
    ON SCHEMA::[Selections] TO [DataOperations]
    WITH GRANT OPTION;


GO
GRANT INSERT
    ON SCHEMA::[Selections] TO [DataOperations]
    WITH GRANT OPTION;


GO
GRANT SELECT
    ON SCHEMA::[Selections] TO [DataOperations]
    WITH GRANT OPTION;


GO
GRANT SELECT
    ON SCHEMA::[Selections] TO [New_Insight];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Selections] TO [New_Insight];


GO
GRANT SELECT
    ON SCHEMA::[Selections] TO [New_DataOps];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Selections] TO [New_DataOps];


GO
GRANT ALTER
    ON SCHEMA::[Selections] TO [New_CampaignOps];


GO
GRANT CONTROL
    ON SCHEMA::[Selections] TO [New_CampaignOps];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[Selections] TO [New_CampaignOps];


GO
GRANT DELETE
    ON SCHEMA::[Selections] TO [New_CampaignOps];


GO
GRANT EXECUTE
    ON SCHEMA::[Selections] TO [New_CampaignOps];


GO
GRANT INSERT
    ON SCHEMA::[Selections] TO [New_CampaignOps];


GO
GRANT REFERENCES
    ON SCHEMA::[Selections] TO [New_CampaignOps];


GO
GRANT SELECT
    ON SCHEMA::[Selections] TO [New_CampaignOps];


GO
GRANT TAKE OWNERSHIP
    ON SCHEMA::[Selections] TO [New_CampaignOps];


GO
GRANT UPDATE
    ON SCHEMA::[Selections] TO [New_CampaignOps];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Selections] TO [New_CampaignOps];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[Selections] TO [New_CampaignOps];


GO
GRANT SELECT
    ON SCHEMA::[Selections] TO [New_BI];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Selections] TO [New_BI];


GO
GRANT ALTER
    ON SCHEMA::[Selections] TO [New_OnCall];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[Selections] TO [New_OnCall];


GO
GRANT DELETE
    ON SCHEMA::[Selections] TO [New_OnCall];


GO
GRANT EXECUTE
    ON SCHEMA::[Selections] TO [New_OnCall];


GO
GRANT INSERT
    ON SCHEMA::[Selections] TO [New_OnCall];


GO
GRANT REFERENCES
    ON SCHEMA::[Selections] TO [New_OnCall];


GO
GRANT SELECT
    ON SCHEMA::[Selections] TO [New_OnCall];


GO
GRANT UPDATE
    ON SCHEMA::[Selections] TO [New_OnCall];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Selections] TO [New_OnCall];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[Selections] TO [New_OnCall];


GO
GRANT SELECT
    ON SCHEMA::[Selections] TO [New_ReadOnly];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Selections] TO [New_ReadOnly];

