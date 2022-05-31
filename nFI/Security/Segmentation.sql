CREATE SCHEMA [Segmentation]
    AUTHORIZATION [dbo];


GO
GRANT EXECUTE
    ON SCHEMA::[Segmentation] TO [DataOperations]
    WITH GRANT OPTION;


GO
GRANT INSERT
    ON SCHEMA::[Segmentation] TO [DataOperations]
    WITH GRANT OPTION;


GO
GRANT SELECT
    ON SCHEMA::[Segmentation] TO [DataOperations]
    WITH GRANT OPTION;


GO
GRANT ALTER
    ON SCHEMA::[Segmentation] TO [Zoe];


GO
GRANT DELETE
    ON SCHEMA::[Segmentation] TO [Zoe];


GO
GRANT EXECUTE
    ON SCHEMA::[Segmentation] TO [Zoe];


GO
GRANT INSERT
    ON SCHEMA::[Segmentation] TO [Zoe];


GO
GRANT SELECT
    ON SCHEMA::[Segmentation] TO [Zoe];


GO
GRANT UPDATE
    ON SCHEMA::[Segmentation] TO [Zoe];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Segmentation] TO [Zoe];


GO
GRANT SELECT
    ON SCHEMA::[Segmentation] TO [New_Insight];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Segmentation] TO [New_Insight];


GO
GRANT SELECT
    ON SCHEMA::[Segmentation] TO [New_DataOps];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Segmentation] TO [New_DataOps];


GO
GRANT ALTER
    ON SCHEMA::[Segmentation] TO [New_CampaignOps];


GO
GRANT CONTROL
    ON SCHEMA::[Segmentation] TO [New_CampaignOps];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[Segmentation] TO [New_CampaignOps];


GO
GRANT DELETE
    ON SCHEMA::[Segmentation] TO [New_CampaignOps];


GO
GRANT EXECUTE
    ON SCHEMA::[Segmentation] TO [New_CampaignOps];


GO
GRANT INSERT
    ON SCHEMA::[Segmentation] TO [New_CampaignOps];


GO
GRANT REFERENCES
    ON SCHEMA::[Segmentation] TO [New_CampaignOps];


GO
GRANT SELECT
    ON SCHEMA::[Segmentation] TO [New_CampaignOps];


GO
GRANT TAKE OWNERSHIP
    ON SCHEMA::[Segmentation] TO [New_CampaignOps];


GO
GRANT UPDATE
    ON SCHEMA::[Segmentation] TO [New_CampaignOps];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Segmentation] TO [New_CampaignOps];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[Segmentation] TO [New_CampaignOps];


GO
GRANT SELECT
    ON SCHEMA::[Segmentation] TO [New_BI];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Segmentation] TO [New_BI];


GO
GRANT ALTER
    ON SCHEMA::[Segmentation] TO [New_OnCall];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[Segmentation] TO [New_OnCall];


GO
GRANT DELETE
    ON SCHEMA::[Segmentation] TO [New_OnCall];


GO
GRANT EXECUTE
    ON SCHEMA::[Segmentation] TO [New_OnCall];


GO
GRANT INSERT
    ON SCHEMA::[Segmentation] TO [New_OnCall];


GO
GRANT REFERENCES
    ON SCHEMA::[Segmentation] TO [New_OnCall];


GO
GRANT SELECT
    ON SCHEMA::[Segmentation] TO [New_OnCall];


GO
GRANT UPDATE
    ON SCHEMA::[Segmentation] TO [New_OnCall];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Segmentation] TO [New_OnCall];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[Segmentation] TO [New_OnCall];


GO
GRANT SELECT
    ON SCHEMA::[Segmentation] TO [New_ReadOnly];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Segmentation] TO [New_ReadOnly];

