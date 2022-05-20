CREATE SCHEMA [inbound]
    AUTHORIZATION [dbo];


GO
GRANT ALTER
    ON SCHEMA::[inbound] TO [New_DataOps];


GO
GRANT CONTROL
    ON SCHEMA::[inbound] TO [New_DataOps];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[inbound] TO [New_DataOps];


GO
GRANT DELETE
    ON SCHEMA::[inbound] TO [New_DataOps];


GO
GRANT EXECUTE
    ON SCHEMA::[inbound] TO [New_DataOps];


GO
GRANT INSERT
    ON SCHEMA::[inbound] TO [New_DataOps];


GO
GRANT REFERENCES
    ON SCHEMA::[inbound] TO [New_DataOps];


GO
GRANT SELECT
    ON SCHEMA::[inbound] TO [New_DataOps];


GO
GRANT TAKE OWNERSHIP
    ON SCHEMA::[inbound] TO [New_DataOps];


GO
GRANT UPDATE
    ON SCHEMA::[inbound] TO [New_DataOps];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[inbound] TO [New_DataOps];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[inbound] TO [New_DataOps];


GO
GRANT SELECT
    ON SCHEMA::[inbound] TO [New_Insight];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[inbound] TO [New_Insight];


GO
GRANT SELECT
    ON SCHEMA::[inbound] TO [New_CampaignOps];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[inbound] TO [New_CampaignOps];


GO
GRANT SELECT
    ON SCHEMA::[inbound] TO [New_BI];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[inbound] TO [New_BI];


GO
GRANT ALTER
    ON SCHEMA::[inbound] TO [New_OnCall];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[inbound] TO [New_OnCall];


GO
GRANT DELETE
    ON SCHEMA::[inbound] TO [New_OnCall];


GO
GRANT EXECUTE
    ON SCHEMA::[inbound] TO [New_OnCall];


GO
GRANT INSERT
    ON SCHEMA::[inbound] TO [New_OnCall];


GO
GRANT REFERENCES
    ON SCHEMA::[inbound] TO [New_OnCall];


GO
GRANT SELECT
    ON SCHEMA::[inbound] TO [New_OnCall];


GO
GRANT UPDATE
    ON SCHEMA::[inbound] TO [New_OnCall];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[inbound] TO [New_OnCall];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[inbound] TO [New_OnCall];


GO
GRANT SELECT
    ON SCHEMA::[inbound] TO [New_ReadOnly];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[inbound] TO [New_ReadOnly];

