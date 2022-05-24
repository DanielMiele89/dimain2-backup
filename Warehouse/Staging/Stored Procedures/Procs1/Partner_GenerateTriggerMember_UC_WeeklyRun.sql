
-- ******************************************************************************
-- Author: Suraj Chahal
-- Create date: 06/01/2015
-- Description: Executes Partner_GenerateTriggerMember for each campaign
--		which has WeeklyExecute = 1 in the PartnerTrigger_UC_Campaigns table
-- ******************************************************************************
CREATE PROCEDURE [Staging].[Partner_GenerateTriggerMember_UC_WeeklyRun]
			
AS
BEGIN
	SET NOCOUNT ON;


/**************************************************************************
*************Get list of PartnerTriggers which need to be run**************
**************************************************************************/
IF OBJECT_ID('Staging.WeeklyPartnerTriggersUC') IS NOT NULL DROP TABLE Staging.WeeklyPartnerTriggersUC
SELECT	ROW_NUMBER() OVER(ORDER BY CampaignID ASC) AS RowNo, 
	CampaignID,
	CampaignName
INTO Staging.WeeklyPartnerTriggersUC		
FROM Warehouse.Relational.PartnerTrigger_UC_Campaigns
WHERE	WeeklyExecute = 1


/**************************************************************************
*************************Loop for all campaigns****************************
**************************************************************************/
DECLARE	@RowNo INT,
	@MaxRowNo INT, 
	@CampaignID INT,
	@CampaignName VARCHAR(200)

SET @RowNo = 1
SET @MaxRowNo = (SELECT MAX(RowNo) FROM Staging.WeeklyPartnerTriggersUC)

--**Loop for each Campaign
WHILE @RowNo <= @MaxRowNo
BEGIN
		SET @CampaignID = (SELECT CampaignID FROM Staging.WeeklyPartnerTriggersUC WHERE RowNo = @RowNo)
		SET @CampaignName = (SELECT CampaignName FROM Staging.WeeklyPartnerTriggersUC WHERE RowNo = @RowNo)
	
		--**Write entry to JobLog_Temp Table
	  	INSERT INTO staging.JobLog_Temp
		SELECT	StoredProcedureName = 'Partner_GenerateTriggerMember_UC_WeeklyRun',
			TableSchemaName = 'Relational',
			TableName = 'PartnerTrigger_UC_Members '+@CampaignName,
			StartDate = GETDATE(),
			EndDate = NULL,
			TableRowCount  = NULL,
			AppendReload = 'R'

		/*********************************************************************
		********Run Staging.Partner_GenerateTriggerMember_UC for Campaign*****
		*********************************************************************/
	  	EXEC Staging.Partner_GenerateTriggerMember_UC @CampaignID
		SET @RowNo = @RowNo + 1
		/*********************************************************************
		**********************************************************************
		*********************************************************************/

		--**Update entry in JobLog_Temp Table with End Date	  
		UPDATE  Staging.JobLog_Temp
		SET	EndDate = GETDATE()
		WHERE	StoredProcedureName = 'Partner_GenerateTriggerMember_UC_WeeklyRun'
			AND TableSchemaName = 'Relational'
			AND TableName = 'PartnerTrigger_UC_Members '+@CampaignName
			AND EndDate is null
		

		--**Update entry in JobLog Table with Row Count
		UPDATE	Staging.JobLog_Temp
		SET	TableRowCount = (SELECT COUNT(1) FROM Warehouse.Relational.PartnerTrigger_UC_Members WHERE CampaignID = @CampaignID)
		WHERE	StoredProcedureName = 'Partner_GenerateTriggerMember_UC_WeeklyRun'
			AND TableSchemaName = 'Relational'
			AND TableName = 'PartnerTrigger_UC_Members '+@CampaignName 
			AND TableRowCount IS NULL


END

--**Add entry in JobLog Table with End Date
INSERT INTO Staging.JobLog
SELECT	StoredProcedureName,
	TableSchemaName,
	TableName,
	StartDate,
	EndDate,
	TableRowCount,
	AppendReload	
FROM Staging.JobLog_Temp

TRUNCATE TABLE staging.JobLog_Temp


END
