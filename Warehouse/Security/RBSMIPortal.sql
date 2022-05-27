﻿CREATE SCHEMA [RBSMIPortal]
    AUTHORIZATION [dbo];




GO
GRANT VIEW DEFINITION
    ON SCHEMA::[RBSMIPortal] TO [New_ReadOnly];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[RBSMIPortal] TO [New_PIIRemoved];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[RBSMIPortal] TO [New_OnCall];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[RBSMIPortal] TO [New_Insight];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[RBSMIPortal] TO [New_DataOps];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[RBSMIPortal] TO [New_CampaignOps];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[RBSMIPortal] TO [New_BI];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[RBSMIPortal] TO [DataTeam];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[RBSMIPortal] TO [New_OnCall];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[RBSMIPortal] TO [New_BI];


GO
GRANT UPDATE
    ON SCHEMA::[RBSMIPortal] TO [New_OnCall];


GO
GRANT UPDATE
    ON SCHEMA::[RBSMIPortal] TO [New_BI];


GO
GRANT UPDATE
    ON SCHEMA::[RBSMIPortal] TO [DataTeam];


GO
GRANT TAKE OWNERSHIP
    ON SCHEMA::[RBSMIPortal] TO [New_BI];


GO
GRANT SELECT
    ON SCHEMA::[RBSMIPortal] TO [New_ReadOnly];


GO
GRANT SELECT
    ON SCHEMA::[RBSMIPortal] TO [New_PIIRemoved];


GO
GRANT SELECT
    ON SCHEMA::[RBSMIPortal] TO [New_OnCall];


GO
GRANT SELECT
    ON SCHEMA::[RBSMIPortal] TO [New_Insight];


GO
GRANT SELECT
    ON SCHEMA::[RBSMIPortal] TO [New_DataOps];


GO
GRANT SELECT
    ON SCHEMA::[RBSMIPortal] TO [New_CampaignOps];


GO
GRANT SELECT
    ON SCHEMA::[RBSMIPortal] TO [New_BI];


GO
GRANT SELECT
    ON SCHEMA::[RBSMIPortal] TO [DataTeam];


GO
GRANT REFERENCES
    ON SCHEMA::[RBSMIPortal] TO [New_OnCall];


GO
GRANT REFERENCES
    ON SCHEMA::[RBSMIPortal] TO [New_BI];


GO
GRANT INSERT
    ON SCHEMA::[RBSMIPortal] TO [New_OnCall];


GO
GRANT INSERT
    ON SCHEMA::[RBSMIPortal] TO [New_BI];


GO
GRANT INSERT
    ON SCHEMA::[RBSMIPortal] TO [DataTeam];


GO
GRANT EXECUTE
    ON SCHEMA::[RBSMIPortal] TO [New_OnCall];


GO
GRANT EXECUTE
    ON SCHEMA::[RBSMIPortal] TO [New_BI];


GO
GRANT DELETE
    ON SCHEMA::[RBSMIPortal] TO [New_OnCall];


GO
GRANT DELETE
    ON SCHEMA::[RBSMIPortal] TO [New_BI];


GO
GRANT DELETE
    ON SCHEMA::[RBSMIPortal] TO [DataTeam];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[RBSMIPortal] TO [New_OnCall];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[RBSMIPortal] TO [New_BI];


GO
GRANT CONTROL
    ON SCHEMA::[RBSMIPortal] TO [New_BI];


GO
GRANT ALTER
    ON SCHEMA::[RBSMIPortal] TO [New_OnCall];


GO
GRANT ALTER
    ON SCHEMA::[RBSMIPortal] TO [New_BI];


GO
GRANT ALTER
    ON SCHEMA::[RBSMIPortal] TO [DataTeam];
