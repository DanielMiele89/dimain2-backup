CREATE SCHEMA [Relational]
    AUTHORIZATION [dbo];


GO
GRANT SELECT
    ON SCHEMA::[Relational] TO [virgin_etl_user];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Relational] TO [New_PIIRemoved];


GO
GRANT SELECT
    ON SCHEMA::[Relational] TO [New_PIIRemoved];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Relational] TO [New_ReadOnly];


GO
GRANT SELECT
    ON SCHEMA::[Relational] TO [New_ReadOnly];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[Relational] TO [New_OnCall];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Relational] TO [New_OnCall];


GO
GRANT UPDATE
    ON SCHEMA::[Relational] TO [New_OnCall];


GO
GRANT SELECT
    ON SCHEMA::[Relational] TO [New_OnCall];


GO
GRANT REFERENCES
    ON SCHEMA::[Relational] TO [New_OnCall];


GO
GRANT INSERT
    ON SCHEMA::[Relational] TO [New_OnCall];


GO
GRANT EXECUTE
    ON SCHEMA::[Relational] TO [New_OnCall];


GO
GRANT DELETE
    ON SCHEMA::[Relational] TO [New_OnCall];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[Relational] TO [New_OnCall];


GO
GRANT ALTER
    ON SCHEMA::[Relational] TO [New_OnCall];


GO
GRANT SELECT
    ON SCHEMA::[Relational] TO [DB5\reportinguser];


GO
GRANT EXECUTE
    ON SCHEMA::[Relational] TO [DB5\reportinguser];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[Relational] TO [New_BI];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Relational] TO [New_BI];


GO
GRANT UPDATE
    ON SCHEMA::[Relational] TO [New_BI];


GO
GRANT SELECT
    ON SCHEMA::[Relational] TO [New_BI];


GO
GRANT REFERENCES
    ON SCHEMA::[Relational] TO [New_BI];


GO
GRANT INSERT
    ON SCHEMA::[Relational] TO [New_BI];


GO
GRANT EXECUTE
    ON SCHEMA::[Relational] TO [New_BI];


GO
GRANT DELETE
    ON SCHEMA::[Relational] TO [New_BI];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[Relational] TO [New_BI];


GO
GRANT ALTER
    ON SCHEMA::[Relational] TO [New_BI];


GO
GRANT UPDATE
    ON SCHEMA::[Relational] TO [gas];


GO
GRANT SELECT
    ON SCHEMA::[Relational] TO [gas];


GO
GRANT INSERT
    ON SCHEMA::[Relational] TO [gas];


GO
GRANT EXECUTE
    ON SCHEMA::[Relational] TO [gas];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[Relational] TO [New_CampaignOps];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Relational] TO [New_CampaignOps];


GO
GRANT UPDATE
    ON SCHEMA::[Relational] TO [New_CampaignOps];


GO
GRANT TAKE OWNERSHIP
    ON SCHEMA::[Relational] TO [New_CampaignOps];


GO
GRANT SELECT
    ON SCHEMA::[Relational] TO [New_CampaignOps];


GO
GRANT REFERENCES
    ON SCHEMA::[Relational] TO [New_CampaignOps];


GO
GRANT INSERT
    ON SCHEMA::[Relational] TO [New_CampaignOps];


GO
GRANT EXECUTE
    ON SCHEMA::[Relational] TO [New_CampaignOps];


GO
GRANT DELETE
    ON SCHEMA::[Relational] TO [New_CampaignOps];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[Relational] TO [New_CampaignOps];


GO
GRANT CONTROL
    ON SCHEMA::[Relational] TO [New_CampaignOps];


GO
GRANT ALTER
    ON SCHEMA::[Relational] TO [New_CampaignOps];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[Relational] TO [New_DataOps];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Relational] TO [New_DataOps];


GO
GRANT UPDATE
    ON SCHEMA::[Relational] TO [New_DataOps];


GO
GRANT SELECT
    ON SCHEMA::[Relational] TO [New_DataOps];


GO
GRANT REFERENCES
    ON SCHEMA::[Relational] TO [New_DataOps];


GO
GRANT INSERT
    ON SCHEMA::[Relational] TO [New_DataOps];


GO
GRANT EXECUTE
    ON SCHEMA::[Relational] TO [New_DataOps];


GO
GRANT DELETE
    ON SCHEMA::[Relational] TO [New_DataOps];


GO
GRANT ALTER
    ON SCHEMA::[Relational] TO [New_DataOps];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Relational] TO [New_Insight];


GO
GRANT SELECT
    ON SCHEMA::[Relational] TO [New_Insight];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Relational] TO [InsightTeam];


GO
GRANT SELECT
    ON SCHEMA::[Relational] TO [InsightTeam];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[Relational] TO [DataTeam];


GO
GRANT UPDATE
    ON SCHEMA::[Relational] TO [DataTeam];


GO
GRANT SELECT
    ON SCHEMA::[Relational] TO [DataTeam];


GO
GRANT INSERT
    ON SCHEMA::[Relational] TO [DataTeam];


GO
GRANT EXECUTE
    ON SCHEMA::[Relational] TO [DataTeam];


GO
GRANT DELETE
    ON SCHEMA::[Relational] TO [DataTeam];


GO
GRANT SELECT
    ON SCHEMA::[Relational] TO [Analytics];


GO
GRANT EXECUTE
    ON SCHEMA::[Relational] TO [Analytics];


GO
GRANT UPDATE
    ON SCHEMA::[Relational] TO [DataMart];


GO
GRANT SELECT
    ON SCHEMA::[Relational] TO [DataMart];


GO
GRANT INSERT
    ON SCHEMA::[Relational] TO [DataMart];


GO
GRANT EXECUTE
    ON SCHEMA::[Relational] TO [DataMart];


GO
GRANT DELETE
    ON SCHEMA::[Relational] TO [DataMart];


GO
GRANT ALTER
    ON SCHEMA::[Relational] TO [DataMart];

