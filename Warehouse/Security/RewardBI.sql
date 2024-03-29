﻿CREATE SCHEMA [RewardBI]
    AUTHORIZATION [dbo];




GO
GRANT VIEW DEFINITION
    ON SCHEMA::[RewardBI] TO [New_ReadOnly];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[RewardBI] TO [New_PIIRemoved];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[RewardBI] TO [New_OnCall];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[RewardBI] TO [New_Insight];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[RewardBI] TO [New_DataOps];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[RewardBI] TO [New_CampaignOps];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[RewardBI] TO [New_BI];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[RewardBI] TO [New_OnCall];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[RewardBI] TO [New_BI];


GO
GRANT UPDATE
    ON SCHEMA::[RewardBI] TO [New_OnCall];


GO
GRANT UPDATE
    ON SCHEMA::[RewardBI] TO [New_BI];


GO
GRANT TAKE OWNERSHIP
    ON SCHEMA::[RewardBI] TO [New_BI];


GO
GRANT SELECT
    ON SCHEMA::[RewardBI] TO [New_ReadOnly];


GO
GRANT SELECT
    ON SCHEMA::[RewardBI] TO [New_PIIRemoved];


GO
GRANT SELECT
    ON SCHEMA::[RewardBI] TO [New_OnCall];


GO
GRANT SELECT
    ON SCHEMA::[RewardBI] TO [New_Insight];


GO
GRANT SELECT
    ON SCHEMA::[RewardBI] TO [New_DataOps];


GO
GRANT SELECT
    ON SCHEMA::[RewardBI] TO [New_CampaignOps];


GO
GRANT SELECT
    ON SCHEMA::[RewardBI] TO [New_BI];


GO
GRANT SELECT
    ON SCHEMA::[RewardBI] TO [gas];


GO
GRANT REFERENCES
    ON SCHEMA::[RewardBI] TO [New_OnCall];


GO
GRANT REFERENCES
    ON SCHEMA::[RewardBI] TO [New_BI];


GO
GRANT INSERT
    ON SCHEMA::[RewardBI] TO [New_OnCall];


GO
GRANT INSERT
    ON SCHEMA::[RewardBI] TO [New_BI];


GO
GRANT INSERT
    ON SCHEMA::[RewardBI] TO [gas];


GO
GRANT EXECUTE
    ON SCHEMA::[RewardBI] TO [New_OnCall];


GO
GRANT EXECUTE
    ON SCHEMA::[RewardBI] TO [New_BI];


GO
GRANT EXECUTE
    ON SCHEMA::[RewardBI] TO [gas];


GO
GRANT DELETE
    ON SCHEMA::[RewardBI] TO [New_OnCall];


GO
GRANT DELETE
    ON SCHEMA::[RewardBI] TO [New_BI];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[RewardBI] TO [New_OnCall];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[RewardBI] TO [New_BI];


GO
GRANT CONTROL
    ON SCHEMA::[RewardBI] TO [New_BI];


GO
GRANT ALTER
    ON SCHEMA::[RewardBI] TO [New_OnCall];


GO
GRANT ALTER
    ON SCHEMA::[RewardBI] TO [New_BI];

