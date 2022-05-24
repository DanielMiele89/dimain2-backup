CREATE SCHEMA [ExcelQuery]
    AUTHORIZATION [dbo];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[ExcelQuery] TO [New_PIIRemoved];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[ExcelQuery] TO [New_PIIRemoved];


GO
GRANT UPDATE
    ON SCHEMA::[ExcelQuery] TO [New_PIIRemoved];


GO
GRANT TAKE OWNERSHIP
    ON SCHEMA::[ExcelQuery] TO [New_PIIRemoved];


GO
GRANT SELECT
    ON SCHEMA::[ExcelQuery] TO [New_PIIRemoved];


GO
GRANT REFERENCES
    ON SCHEMA::[ExcelQuery] TO [New_PIIRemoved];


GO
GRANT INSERT
    ON SCHEMA::[ExcelQuery] TO [New_PIIRemoved];


GO
GRANT EXECUTE
    ON SCHEMA::[ExcelQuery] TO [New_PIIRemoved];


GO
GRANT DELETE
    ON SCHEMA::[ExcelQuery] TO [New_PIIRemoved];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[ExcelQuery] TO [New_PIIRemoved];


GO
GRANT CONTROL
    ON SCHEMA::[ExcelQuery] TO [New_PIIRemoved];


GO
GRANT ALTER
    ON SCHEMA::[ExcelQuery] TO [New_PIIRemoved];


GO
GRANT SELECT
    ON SCHEMA::[ExcelQuery] TO [Zoe];


GO
GRANT INSERT
    ON SCHEMA::[ExcelQuery] TO [Zoe];


GO
GRANT ALTER
    ON SCHEMA::[ExcelQuery] TO [Zoe];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[ExcelQuery] TO [ExcelQueryUser];


GO
GRANT UPDATE
    ON SCHEMA::[ExcelQuery] TO [ExcelQueryUser];


GO
GRANT SELECT
    ON SCHEMA::[ExcelQuery] TO [ExcelQueryUser];


GO
GRANT INSERT
    ON SCHEMA::[ExcelQuery] TO [ExcelQueryUser];


GO
GRANT EXECUTE
    ON SCHEMA::[ExcelQuery] TO [ExcelQueryUser];


GO
GRANT ALTER
    ON SCHEMA::[ExcelQuery] TO [ExcelQueryUser];


GO
GRANT EXECUTE
    ON SCHEMA::[ExcelQuery] TO [ExcelQueryOp];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[ExcelQuery] TO [New_ReadOnly];


GO
GRANT SELECT
    ON SCHEMA::[ExcelQuery] TO [New_ReadOnly];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[ExcelQuery] TO [New_OnCall];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[ExcelQuery] TO [New_OnCall];


GO
GRANT UPDATE
    ON SCHEMA::[ExcelQuery] TO [New_OnCall];


GO
GRANT SELECT
    ON SCHEMA::[ExcelQuery] TO [New_OnCall];


GO
GRANT REFERENCES
    ON SCHEMA::[ExcelQuery] TO [New_OnCall];


GO
GRANT INSERT
    ON SCHEMA::[ExcelQuery] TO [New_OnCall];


GO
GRANT EXECUTE
    ON SCHEMA::[ExcelQuery] TO [New_OnCall];


GO
GRANT DELETE
    ON SCHEMA::[ExcelQuery] TO [New_OnCall];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[ExcelQuery] TO [New_OnCall];


GO
GRANT ALTER
    ON SCHEMA::[ExcelQuery] TO [New_OnCall];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[ExcelQuery] TO [New_BI];


GO
GRANT SELECT
    ON SCHEMA::[ExcelQuery] TO [New_BI];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[ExcelQuery] TO [New_CampaignOps];


GO
GRANT SELECT
    ON SCHEMA::[ExcelQuery] TO [New_CampaignOps];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[ExcelQuery] TO [New_DataOps];


GO
GRANT SELECT
    ON SCHEMA::[ExcelQuery] TO [New_DataOps];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[ExcelQuery] TO [New_Insight];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[ExcelQuery] TO [New_Insight];


GO
GRANT UPDATE
    ON SCHEMA::[ExcelQuery] TO [New_Insight];


GO
GRANT TAKE OWNERSHIP
    ON SCHEMA::[ExcelQuery] TO [New_Insight];


GO
GRANT SELECT
    ON SCHEMA::[ExcelQuery] TO [New_Insight];


GO
GRANT REFERENCES
    ON SCHEMA::[ExcelQuery] TO [New_Insight];


GO
GRANT INSERT
    ON SCHEMA::[ExcelQuery] TO [New_Insight];


GO
GRANT EXECUTE
    ON SCHEMA::[ExcelQuery] TO [New_Insight];


GO
GRANT DELETE
    ON SCHEMA::[ExcelQuery] TO [New_Insight];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[ExcelQuery] TO [New_Insight];


GO
GRANT CONTROL
    ON SCHEMA::[ExcelQuery] TO [New_Insight];


GO
GRANT ALTER
    ON SCHEMA::[ExcelQuery] TO [New_Insight];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[ExcelQuery] TO [InsightTeam];


GO
GRANT UPDATE
    ON SCHEMA::[ExcelQuery] TO [InsightTeam];


GO
GRANT SELECT
    ON SCHEMA::[ExcelQuery] TO [InsightTeam];


GO
GRANT REFERENCES
    ON SCHEMA::[ExcelQuery] TO [InsightTeam];


GO
GRANT INSERT
    ON SCHEMA::[ExcelQuery] TO [InsightTeam];


GO
GRANT EXECUTE
    ON SCHEMA::[ExcelQuery] TO [InsightTeam];


GO
GRANT DELETE
    ON SCHEMA::[ExcelQuery] TO [InsightTeam];


GO
GRANT ALTER
    ON SCHEMA::[ExcelQuery] TO [InsightTeam];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[ExcelQuery] TO [DataTeam];


GO
GRANT UPDATE
    ON SCHEMA::[ExcelQuery] TO [DataTeam];


GO
GRANT SELECT
    ON SCHEMA::[ExcelQuery] TO [DataTeam];


GO
GRANT REFERENCES
    ON SCHEMA::[ExcelQuery] TO [DataTeam];


GO
GRANT INSERT
    ON SCHEMA::[ExcelQuery] TO [DataTeam];


GO
GRANT EXECUTE
    ON SCHEMA::[ExcelQuery] TO [DataTeam];


GO
GRANT DELETE
    ON SCHEMA::[ExcelQuery] TO [DataTeam];


GO
GRANT ALTER
    ON SCHEMA::[ExcelQuery] TO [DataTeam];

