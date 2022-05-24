CREATE SCHEMA [Prototype]
    AUTHORIZATION [dbo];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[Prototype] TO [New_PIIRemoved];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Prototype] TO [New_PIIRemoved];


GO
GRANT UPDATE
    ON SCHEMA::[Prototype] TO [New_PIIRemoved];


GO
GRANT TAKE OWNERSHIP
    ON SCHEMA::[Prototype] TO [New_PIIRemoved];


GO
GRANT SELECT
    ON SCHEMA::[Prototype] TO [New_PIIRemoved];


GO
GRANT REFERENCES
    ON SCHEMA::[Prototype] TO [New_PIIRemoved];


GO
GRANT INSERT
    ON SCHEMA::[Prototype] TO [New_PIIRemoved];


GO
GRANT EXECUTE
    ON SCHEMA::[Prototype] TO [New_PIIRemoved];


GO
GRANT DELETE
    ON SCHEMA::[Prototype] TO [New_PIIRemoved];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[Prototype] TO [New_PIIRemoved];


GO
GRANT CONTROL
    ON SCHEMA::[Prototype] TO [New_PIIRemoved];


GO
GRANT ALTER
    ON SCHEMA::[Prototype] TO [New_PIIRemoved];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Prototype] TO [New_ReadOnly];


GO
GRANT SELECT
    ON SCHEMA::[Prototype] TO [New_ReadOnly];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[Prototype] TO [New_OnCall];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Prototype] TO [New_OnCall];


GO
GRANT UPDATE
    ON SCHEMA::[Prototype] TO [New_OnCall];


GO
GRANT SELECT
    ON SCHEMA::[Prototype] TO [New_OnCall];


GO
GRANT REFERENCES
    ON SCHEMA::[Prototype] TO [New_OnCall];


GO
GRANT INSERT
    ON SCHEMA::[Prototype] TO [New_OnCall];


GO
GRANT EXECUTE
    ON SCHEMA::[Prototype] TO [New_OnCall];


GO
GRANT DELETE
    ON SCHEMA::[Prototype] TO [New_OnCall];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[Prototype] TO [New_OnCall];


GO
GRANT ALTER
    ON SCHEMA::[Prototype] TO [New_OnCall];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[Prototype] TO [New_BI];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Prototype] TO [New_BI];


GO
GRANT UPDATE
    ON SCHEMA::[Prototype] TO [New_BI];


GO
GRANT TAKE OWNERSHIP
    ON SCHEMA::[Prototype] TO [New_BI];


GO
GRANT SELECT
    ON SCHEMA::[Prototype] TO [New_BI];


GO
GRANT REFERENCES
    ON SCHEMA::[Prototype] TO [New_BI];


GO
GRANT INSERT
    ON SCHEMA::[Prototype] TO [New_BI];


GO
GRANT EXECUTE
    ON SCHEMA::[Prototype] TO [New_BI];


GO
GRANT DELETE
    ON SCHEMA::[Prototype] TO [New_BI];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[Prototype] TO [New_BI];


GO
GRANT CONTROL
    ON SCHEMA::[Prototype] TO [New_BI];


GO
GRANT ALTER
    ON SCHEMA::[Prototype] TO [New_BI];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[Prototype] TO [New_CampaignOps];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Prototype] TO [New_CampaignOps];


GO
GRANT UPDATE
    ON SCHEMA::[Prototype] TO [New_CampaignOps];


GO
GRANT TAKE OWNERSHIP
    ON SCHEMA::[Prototype] TO [New_CampaignOps];


GO
GRANT SELECT
    ON SCHEMA::[Prototype] TO [New_CampaignOps];


GO
GRANT REFERENCES
    ON SCHEMA::[Prototype] TO [New_CampaignOps];


GO
GRANT INSERT
    ON SCHEMA::[Prototype] TO [New_CampaignOps];


GO
GRANT EXECUTE
    ON SCHEMA::[Prototype] TO [New_CampaignOps];


GO
GRANT DELETE
    ON SCHEMA::[Prototype] TO [New_CampaignOps];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[Prototype] TO [New_CampaignOps];


GO
GRANT CONTROL
    ON SCHEMA::[Prototype] TO [New_CampaignOps];


GO
GRANT ALTER
    ON SCHEMA::[Prototype] TO [New_CampaignOps];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[Prototype] TO [New_DataOps];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Prototype] TO [New_DataOps];


GO
GRANT UPDATE
    ON SCHEMA::[Prototype] TO [New_DataOps];


GO
GRANT TAKE OWNERSHIP
    ON SCHEMA::[Prototype] TO [New_DataOps];


GO
GRANT SELECT
    ON SCHEMA::[Prototype] TO [New_DataOps];


GO
GRANT REFERENCES
    ON SCHEMA::[Prototype] TO [New_DataOps];


GO
GRANT INSERT
    ON SCHEMA::[Prototype] TO [New_DataOps];


GO
GRANT EXECUTE
    ON SCHEMA::[Prototype] TO [New_DataOps];


GO
GRANT DELETE
    ON SCHEMA::[Prototype] TO [New_DataOps];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[Prototype] TO [New_DataOps];


GO
GRANT CONTROL
    ON SCHEMA::[Prototype] TO [New_DataOps];


GO
GRANT ALTER
    ON SCHEMA::[Prototype] TO [New_DataOps];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[Prototype] TO [New_Insight];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Prototype] TO [New_Insight];


GO
GRANT UPDATE
    ON SCHEMA::[Prototype] TO [New_Insight];


GO
GRANT TAKE OWNERSHIP
    ON SCHEMA::[Prototype] TO [New_Insight];


GO
GRANT SELECT
    ON SCHEMA::[Prototype] TO [New_Insight];


GO
GRANT REFERENCES
    ON SCHEMA::[Prototype] TO [New_Insight];


GO
GRANT INSERT
    ON SCHEMA::[Prototype] TO [New_Insight];


GO
GRANT EXECUTE
    ON SCHEMA::[Prototype] TO [New_Insight];


GO
GRANT DELETE
    ON SCHEMA::[Prototype] TO [New_Insight];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[Prototype] TO [New_Insight];


GO
GRANT CONTROL
    ON SCHEMA::[Prototype] TO [New_Insight];


GO
GRANT ALTER
    ON SCHEMA::[Prototype] TO [New_Insight];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Prototype] TO [InsightTeam];


GO
GRANT UPDATE
    ON SCHEMA::[Prototype] TO [InsightTeam];


GO
GRANT SELECT
    ON SCHEMA::[Prototype] TO [InsightTeam];


GO
GRANT INSERT
    ON SCHEMA::[Prototype] TO [InsightTeam];


GO
GRANT EXECUTE
    ON SCHEMA::[Prototype] TO [InsightTeam];


GO
GRANT DELETE
    ON SCHEMA::[Prototype] TO [InsightTeam];


GO
GRANT ALTER
    ON SCHEMA::[Prototype] TO [InsightTeam];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Prototype] TO [DataTeam];


GO
GRANT UPDATE
    ON SCHEMA::[Prototype] TO [DataTeam];


GO
GRANT SELECT
    ON SCHEMA::[Prototype] TO [DataTeam];


GO
GRANT REFERENCES
    ON SCHEMA::[Prototype] TO [DataTeam];


GO
GRANT INSERT
    ON SCHEMA::[Prototype] TO [DataTeam];


GO
GRANT EXECUTE
    ON SCHEMA::[Prototype] TO [DataTeam];


GO
GRANT DELETE
    ON SCHEMA::[Prototype] TO [DataTeam];


GO
GRANT ALTER
    ON SCHEMA::[Prototype] TO [DataTeam];

