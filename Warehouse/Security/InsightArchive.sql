CREATE SCHEMA [InsightArchive]
    AUTHORIZATION [dbo];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[InsightArchive] TO [New_PIIRemoved];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[InsightArchive] TO [New_PIIRemoved];


GO
GRANT UPDATE
    ON SCHEMA::[InsightArchive] TO [New_PIIRemoved];


GO
GRANT TAKE OWNERSHIP
    ON SCHEMA::[InsightArchive] TO [New_PIIRemoved];


GO
GRANT SELECT
    ON SCHEMA::[InsightArchive] TO [New_PIIRemoved];


GO
GRANT REFERENCES
    ON SCHEMA::[InsightArchive] TO [New_PIIRemoved];


GO
GRANT INSERT
    ON SCHEMA::[InsightArchive] TO [New_PIIRemoved];


GO
GRANT EXECUTE
    ON SCHEMA::[InsightArchive] TO [New_PIIRemoved];


GO
GRANT DELETE
    ON SCHEMA::[InsightArchive] TO [New_PIIRemoved];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[InsightArchive] TO [New_PIIRemoved];


GO
GRANT CONTROL
    ON SCHEMA::[InsightArchive] TO [New_PIIRemoved];


GO
GRANT ALTER
    ON SCHEMA::[InsightArchive] TO [New_PIIRemoved];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[InsightArchive] TO [New_ReadOnly];


GO
GRANT SELECT
    ON SCHEMA::[InsightArchive] TO [New_ReadOnly];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[InsightArchive] TO [New_OnCall];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[InsightArchive] TO [New_OnCall];


GO
GRANT UPDATE
    ON SCHEMA::[InsightArchive] TO [New_OnCall];


GO
GRANT SELECT
    ON SCHEMA::[InsightArchive] TO [New_OnCall];


GO
GRANT REFERENCES
    ON SCHEMA::[InsightArchive] TO [New_OnCall];


GO
GRANT INSERT
    ON SCHEMA::[InsightArchive] TO [New_OnCall];


GO
GRANT EXECUTE
    ON SCHEMA::[InsightArchive] TO [New_OnCall];


GO
GRANT DELETE
    ON SCHEMA::[InsightArchive] TO [New_OnCall];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[InsightArchive] TO [New_OnCall];


GO
GRANT ALTER
    ON SCHEMA::[InsightArchive] TO [New_OnCall];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[InsightArchive] TO [New_BI];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[InsightArchive] TO [New_BI];


GO
GRANT UPDATE
    ON SCHEMA::[InsightArchive] TO [New_BI];


GO
GRANT SELECT
    ON SCHEMA::[InsightArchive] TO [New_BI];


GO
GRANT REFERENCES
    ON SCHEMA::[InsightArchive] TO [New_BI];


GO
GRANT INSERT
    ON SCHEMA::[InsightArchive] TO [New_BI];


GO
GRANT EXECUTE
    ON SCHEMA::[InsightArchive] TO [New_BI];


GO
GRANT DELETE
    ON SCHEMA::[InsightArchive] TO [New_BI];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[InsightArchive] TO [New_BI];


GO
GRANT ALTER
    ON SCHEMA::[InsightArchive] TO [New_BI];


GO
GRANT SELECT
    ON SCHEMA::[InsightArchive] TO [Ed];


GO
GRANT UPDATE
    ON SCHEMA::[InsightArchive] TO [Stuart];


GO
GRANT SELECT
    ON SCHEMA::[InsightArchive] TO [Stuart];


GO
GRANT INSERT
    ON SCHEMA::[InsightArchive] TO [Stuart];


GO
GRANT DELETE
    ON SCHEMA::[InsightArchive] TO [Stuart];


GO
GRANT ALTER
    ON SCHEMA::[InsightArchive] TO [Stuart];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[InsightArchive] TO [New_CampaignOps];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[InsightArchive] TO [New_CampaignOps];


GO
GRANT UPDATE
    ON SCHEMA::[InsightArchive] TO [New_CampaignOps];


GO
GRANT SELECT
    ON SCHEMA::[InsightArchive] TO [New_CampaignOps];


GO
GRANT REFERENCES
    ON SCHEMA::[InsightArchive] TO [New_CampaignOps];


GO
GRANT INSERT
    ON SCHEMA::[InsightArchive] TO [New_CampaignOps];


GO
GRANT EXECUTE
    ON SCHEMA::[InsightArchive] TO [New_CampaignOps];


GO
GRANT DELETE
    ON SCHEMA::[InsightArchive] TO [New_CampaignOps];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[InsightArchive] TO [New_CampaignOps];


GO
GRANT ALTER
    ON SCHEMA::[InsightArchive] TO [New_CampaignOps];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[InsightArchive] TO [New_DataOps];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[InsightArchive] TO [New_DataOps];


GO
GRANT UPDATE
    ON SCHEMA::[InsightArchive] TO [New_DataOps];


GO
GRANT SELECT
    ON SCHEMA::[InsightArchive] TO [New_DataOps];


GO
GRANT REFERENCES
    ON SCHEMA::[InsightArchive] TO [New_DataOps];


GO
GRANT INSERT
    ON SCHEMA::[InsightArchive] TO [New_DataOps];


GO
GRANT EXECUTE
    ON SCHEMA::[InsightArchive] TO [New_DataOps];


GO
GRANT DELETE
    ON SCHEMA::[InsightArchive] TO [New_DataOps];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[InsightArchive] TO [New_DataOps];


GO
GRANT ALTER
    ON SCHEMA::[InsightArchive] TO [New_DataOps];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[InsightArchive] TO [New_Insight];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[InsightArchive] TO [New_Insight];


GO
GRANT UPDATE
    ON SCHEMA::[InsightArchive] TO [New_Insight];


GO
GRANT TAKE OWNERSHIP
    ON SCHEMA::[InsightArchive] TO [New_Insight];


GO
GRANT SELECT
    ON SCHEMA::[InsightArchive] TO [New_Insight];


GO
GRANT REFERENCES
    ON SCHEMA::[InsightArchive] TO [New_Insight];


GO
GRANT INSERT
    ON SCHEMA::[InsightArchive] TO [New_Insight];


GO
GRANT EXECUTE
    ON SCHEMA::[InsightArchive] TO [New_Insight];


GO
GRANT DELETE
    ON SCHEMA::[InsightArchive] TO [New_Insight];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[InsightArchive] TO [New_Insight];


GO
GRANT CONTROL
    ON SCHEMA::[InsightArchive] TO [New_Insight];


GO
GRANT ALTER
    ON SCHEMA::[InsightArchive] TO [New_Insight];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[InsightArchive] TO [InsightTeam];


GO
GRANT UPDATE
    ON SCHEMA::[InsightArchive] TO [InsightTeam];


GO
GRANT SELECT
    ON SCHEMA::[InsightArchive] TO [InsightTeam];


GO
GRANT REFERENCES
    ON SCHEMA::[InsightArchive] TO [InsightTeam];


GO
GRANT INSERT
    ON SCHEMA::[InsightArchive] TO [InsightTeam];


GO
GRANT EXECUTE
    ON SCHEMA::[InsightArchive] TO [InsightTeam];


GO
GRANT DELETE
    ON SCHEMA::[InsightArchive] TO [InsightTeam];


GO
GRANT ALTER
    ON SCHEMA::[InsightArchive] TO [InsightTeam];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[InsightArchive] TO [DataTeam];


GO
GRANT UPDATE
    ON SCHEMA::[InsightArchive] TO [DataTeam];


GO
GRANT SELECT
    ON SCHEMA::[InsightArchive] TO [DataTeam];


GO
GRANT REFERENCES
    ON SCHEMA::[InsightArchive] TO [DataTeam];


GO
GRANT INSERT
    ON SCHEMA::[InsightArchive] TO [DataTeam];


GO
GRANT EXECUTE
    ON SCHEMA::[InsightArchive] TO [DataTeam];


GO
GRANT DELETE
    ON SCHEMA::[InsightArchive] TO [DataTeam];


GO
GRANT ALTER
    ON SCHEMA::[InsightArchive] TO [DataTeam];


GO
GRANT UPDATE
    ON SCHEMA::[InsightArchive] TO [Prakash];


GO
GRANT SELECT
    ON SCHEMA::[InsightArchive] TO [Prakash];


GO
GRANT INSERT
    ON SCHEMA::[InsightArchive] TO [Prakash];


GO
GRANT DELETE
    ON SCHEMA::[InsightArchive] TO [Prakash];


GO
GRANT ALTER
    ON SCHEMA::[InsightArchive] TO [Prakash];

