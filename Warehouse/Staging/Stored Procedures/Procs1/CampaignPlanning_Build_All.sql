
/******************************************************************************
CAMPAIGN PLANNING TOOL OVERARCHING SCRIPT
-----------------------------------------
-- Author: Suraj Chahal
-- Create date: 27/10/2015
-- Description: Executes the Campaign Planning Stored Procedures


-- Staging.CampaignPlanning_1_UniverseBuild
-- Staging.CampaignPlanning_2_TransactionalData
-- Staging.CampaignPlanning_3_SeasonalityData
*******************************************************************************/

CREATE PROCEDURE [Staging].[CampaignPlanning_Build_All]
									
AS
BEGIN
	SET NOCOUNT ON;


DECLARE @time DATETIME,
        @msg VARCHAR(2048)


IF DATENAME(DW,GETDATE()) = 'Sunday' 
BEGIN 


--Write entry to JobLog Table
INSERT INTO staging.JobLog_Temp
SELECT	StoredProcedureName = 'CampaignPlanning_Build_All',
	TableSchemaName = 'Multiple',
	TableName = 'Building the Customer Universe',
	StartDate = GETDATE(),
	EndDate = NULL,
	TableRowCount  = NULL,
	AppendReload = 'R'

/********************************************************************************/
	--SELECT @msg = 'Script 1 - Building the Customer Universe'
	--EXEC Warehouse.Staging.oo_TimerMessage @msg, @time OUTPUT
	---------------------------------------------------------
	EXEC Staging.CampaignPlanning_1_UniverseBuild
/********************************************************************************/

--Update entry in JobLog Table with End Date
UPDATE staging.JobLog_Temp
SET EndDate = GETDATE()
WHERE	StoredProcedureName = 'CampaignPlanning_Build_All' 
	AND TableSchemaName = 'Multiple' 
	AND TableName = 'Building the Customer Universe' 
	AND EndDate IS NULL
	
--Update entry in JobLog Table with Row Count
UPDATE staging.JobLog_Temp
SET TableRowCount = NULL
WHERE	StoredProcedureName = 'CampaignPlanning_Build_All' 
	AND TableSchemaName = 'Multiple' 
	AND TableName = 'Building the Customer Universe' 
	AND TableRowCount IS NULL
-----------------------------------------------------------------------------------------


--Write entry to JobLog Table
INSERT INTO staging.JobLog_Temp
SELECT	StoredProcedureName = 'CampaignPlanning_Build_All',
	TableSchemaName = 'Multiple',
	TableName = 'Building the Transactional Data',
	StartDate = GETDATE(),
	EndDate = NULL,
	TableRowCount  = NULL,
	AppendReload = 'R'


/********************************************************************************/
	--SELECT @msg = 'Script 2 - Building the Transactional Data'
	--EXEC Warehouse.Staging.oo_TimerMessage @msg, @time OUTPUT
	---------------------------------------------------------
	EXEC Staging.CampaignPlanning_2_TransactionalData
/********************************************************************************/

--Update entry in JobLog Table with End Date
UPDATE staging.JobLog_Temp
SET EndDate = GETDATE()
WHERE	StoredProcedureName = 'CampaignPlanning_Build_All' 
	AND TableSchemaName = 'Multiple' 
	AND TableName = 'Building the Transactional Data' 
	AND EndDate IS NULL
	
--Update entry in JobLog Table with Row Count
UPDATE staging.JobLog_Temp
SET TableRowCount = NULL
WHERE	StoredProcedureName = 'CampaignPlanning_Build_All' 
	AND TableSchemaName = 'Multiple' 
	AND TableName = 'Building the Transactional Data' 
	AND TableRowCount IS NULL
-----------------------------------------------------------------------------------------


--Write entry to JobLog Table
INSERT INTO staging.JobLog_Temp
SELECT	StoredProcedureName = 'CampaignPlanning_Build_All',
	TableSchemaName = 'Multiple',
	TableName = 'Building the Seasonality Data',
	StartDate = GETDATE(),
	EndDate = NULL,
	TableRowCount  = NULL,
	AppendReload = 'R'


/********************************************************************************/
	--SELECT @msg = 'Script 3 - Building the Seasonality Data'
	--EXEC Warehouse.Staging.oo_TimerMessage @msg, @time OUTPUT
	---------------------------------------------------------
	EXEC Staging.CampaignPlanning_3_SeasonalityData
/********************************************************************************/

--Update entry in JobLog Table with End Date
UPDATE staging.JobLog_Temp
SET EndDate = GETDATE()
WHERE	StoredProcedureName = 'CampaignPlanning_Build_All' 
	AND TableSchemaName = 'Multiple' 
	AND TableName = 'Building the Seasonality Data' 
	AND EndDate IS NULL
	
--Update entry in JobLog Table with Row Count
UPDATE staging.JobLog_Temp
SET TableRowCount = NULL
WHERE	StoredProcedureName = 'CampaignPlanning_Build_All' 
	AND TableSchemaName = 'Multiple' 
	AND TableName = 'Building the Seasonality Data' 
	AND TableRowCount IS NULL
-----------------------------------------------------------------------------------------

INSERT INTO staging.JobLog
SELECT	StoredProcedureName,
	TableSchemaName,
	TableName,
	StartDate,
	EndDate,
	TableRowCount,
	AppendReload
FROM staging.JobLog_Temp

TRUNCATE TABLE staging.JobLog_Temp

END

END