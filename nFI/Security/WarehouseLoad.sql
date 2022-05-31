CREATE SCHEMA [WarehouseLoad]
    AUTHORIZATION [dbo];


GO
GRANT SELECT
    ON SCHEMA::[WarehouseLoad] TO [New_Insight];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[WarehouseLoad] TO [New_Insight];


GO
GRANT SELECT
    ON SCHEMA::[WarehouseLoad] TO [New_DataOps];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[WarehouseLoad] TO [New_DataOps];


GO
GRANT ALTER
    ON SCHEMA::[WarehouseLoad] TO [New_CampaignOps];


GO
GRANT CONTROL
    ON SCHEMA::[WarehouseLoad] TO [New_CampaignOps];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[WarehouseLoad] TO [New_CampaignOps];


GO
GRANT DELETE
    ON SCHEMA::[WarehouseLoad] TO [New_CampaignOps];


GO
GRANT EXECUTE
    ON SCHEMA::[WarehouseLoad] TO [New_CampaignOps];


GO
GRANT INSERT
    ON SCHEMA::[WarehouseLoad] TO [New_CampaignOps];


GO
GRANT REFERENCES
    ON SCHEMA::[WarehouseLoad] TO [New_CampaignOps];


GO
GRANT SELECT
    ON SCHEMA::[WarehouseLoad] TO [New_CampaignOps];


GO
GRANT TAKE OWNERSHIP
    ON SCHEMA::[WarehouseLoad] TO [New_CampaignOps];


GO
GRANT UPDATE
    ON SCHEMA::[WarehouseLoad] TO [New_CampaignOps];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[WarehouseLoad] TO [New_CampaignOps];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[WarehouseLoad] TO [New_CampaignOps];


GO
GRANT SELECT
    ON SCHEMA::[WarehouseLoad] TO [New_BI];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[WarehouseLoad] TO [New_BI];


GO
GRANT ALTER
    ON SCHEMA::[WarehouseLoad] TO [New_OnCall];


GO
GRANT CREATE SEQUENCE
    ON SCHEMA::[WarehouseLoad] TO [New_OnCall];


GO
GRANT DELETE
    ON SCHEMA::[WarehouseLoad] TO [New_OnCall];


GO
GRANT EXECUTE
    ON SCHEMA::[WarehouseLoad] TO [New_OnCall];


GO
GRANT INSERT
    ON SCHEMA::[WarehouseLoad] TO [New_OnCall];


GO
GRANT REFERENCES
    ON SCHEMA::[WarehouseLoad] TO [New_OnCall];


GO
GRANT SELECT
    ON SCHEMA::[WarehouseLoad] TO [New_OnCall];


GO
GRANT UPDATE
    ON SCHEMA::[WarehouseLoad] TO [New_OnCall];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[WarehouseLoad] TO [New_OnCall];


GO
GRANT VIEW CHANGE TRACKING
    ON SCHEMA::[WarehouseLoad] TO [New_OnCall];


GO
GRANT SELECT
    ON SCHEMA::[WarehouseLoad] TO [New_ReadOnly];


GO
GRANT VIEW DEFINITION
    ON SCHEMA::[WarehouseLoad] TO [New_ReadOnly];

