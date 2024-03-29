﻿CREATE SCHEMA [AWSFile]
    AUTHORIZATION [dbo];




GO
GRANT VIEW DEFINITION
    ON SCHEMA::[AWSFile] TO [New_ReadOnly];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[AWSFile] TO [New_PIIRemoved];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[AWSFile] TO [New_OnCall];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[AWSFile] TO [New_Insight];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[AWSFile] TO [New_DataOps];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[AWSFile] TO [New_CampaignOps];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[AWSFile] TO [New_BI];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[AWSFile] TO [New_OnCall];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[AWSFile] TO [New_BI];


GO
GRANT UPDATE
    ON SCHEMA::[AWSFile] TO [New_OnCall];


GO
GRANT UPDATE
    ON SCHEMA::[AWSFile] TO [New_BI];


GO
GRANT TAKE OWNERSHIP
    ON SCHEMA::[AWSFile] TO [New_BI];


GO
GRANT SELECT
    ON SCHEMA::[AWSFile] TO [New_ReadOnly];


GO
GRANT SELECT
    ON SCHEMA::[AWSFile] TO [New_PIIRemoved];


GO
GRANT SELECT
    ON SCHEMA::[AWSFile] TO [New_OnCall];


GO
GRANT SELECT
    ON SCHEMA::[AWSFile] TO [New_Insight];


GO
GRANT SELECT
    ON SCHEMA::[AWSFile] TO [New_DataOps];


GO
GRANT SELECT
    ON SCHEMA::[AWSFile] TO [New_CampaignOps];


GO
GRANT SELECT
    ON SCHEMA::[AWSFile] TO [New_BI];


GO
GRANT REFERENCES
    ON SCHEMA::[AWSFile] TO [New_OnCall];


GO
GRANT REFERENCES
    ON SCHEMA::[AWSFile] TO [New_BI];


GO
GRANT INSERT
    ON SCHEMA::[AWSFile] TO [New_OnCall];


GO
GRANT INSERT
    ON SCHEMA::[AWSFile] TO [New_BI];


GO
GRANT EXECUTE
    ON SCHEMA::[AWSFile] TO [New_OnCall];


GO
GRANT EXECUTE
    ON SCHEMA::[AWSFile] TO [New_BI];


GO
GRANT EXECUTE
    ON SCHEMA::[AWSFile] TO [dops_066];


GO
GRANT EXECUTE
    ON SCHEMA::[AWSFile] TO [dimain2\danieldimain2];


GO
GRANT EXECUTE
    ON SCHEMA::[AWSFile] TO [DanielM];


GO
GRANT EXECUTE
    ON SCHEMA::[AWSFile] TO [BIDIMAINETLUser];


GO
GRANT DELETE
    ON SCHEMA::[AWSFile] TO [New_OnCall];


GO
GRANT DELETE
    ON SCHEMA::[AWSFile] TO [New_BI];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[AWSFile] TO [New_OnCall];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[AWSFile] TO [New_BI];


GO
GRANT CONTROL
    ON SCHEMA::[AWSFile] TO [New_BI];


GO
GRANT ALTER
    ON SCHEMA::[AWSFile] TO [New_OnCall];


GO
GRANT ALTER
    ON SCHEMA::[AWSFile] TO [New_BI];

