-- =============================================
-- Author:		Dorota
-- Create date:	15/05/2015
-- =============================================

CREATE PROCEDURE [MI].[CampaignResults_Calculate_Bespoke] (@ClientServicesRef varchar(25)=NULL, @StartDate DATE=NULL, @DatabaseName NVARCHAR(400)='Sandbox', @Bespoke int) AS -- -- unhide this row to modify SP
--DECLARE @ClientServicesRef varchar(25); SET @ClientServicesRef=?, DECLARE @DatabaseName NVARCHAR(400); SET @DatabaseName='Sandbox'  -- unhide this row to run code once

BEGIN 
-- Log when Store Procedure started running in CamapainResults_Log
INSERT INTO Warehouse.MI.Campaign_Log
(StoreProcedureName,  
Parameter_ClientServicesRef, Parameter_StartDate, Parameter_DatabaseName,
RunByUser , RunStartTime)
SELECT 'CampaignResults_Calculate', 
@ClientServicesRef, @StartDate,  @DatabaseName,
SYSTEM_USER, GETDATE()

-- Store RowID for curently running Store Procedure
DECLARE @MY_ID AS INT;
SET @MY_ID= (SELECT SCOPE_IDENTITY());

-- Check if selected combination of ClientServicesRef and StartDate exists in Warehouse.MI.CampaignDetailsWave
-- Otherwise show error message 
-- Check if at leastt 1 control group exists
    -- Otherwise measure campaign and store calculations in working tables

-- Log when Part1 started running
UPDATE Warehouse.MI.Campaign_Log
SET RunStartTime_Part1=GETDATE()
WHERE ID=@MY_ID
--PRINT 'Part1'
EXEC MI. CampaignResults_Calculate_Part1_Bespoke @ClientServicesRef, @StartDate, @DatabaseName, @Bespoke
    
-- Log when Part2 started running
UPDATE Warehouse.MI.Campaign_Log
SET RunStartTime_Part2=GETDATE()
WHERE ID=@MY_ID
-- PRINT 'Part2'
EXEC MI. CampaignResults_Calculate_Part2 @DatabaseName

-- Log when Part3 started running
UPDATE Warehouse.MI.Campaign_Log
SET RunStartTime_Part3=GETDATE()
WHERE ID=@MY_ID
--PRINT 'Part3'
EXEC MI. CampaignResults_Calculate_Part3 @DatabaseName

-- Log when Part4 started running
UPDATE Warehouse.MI.Campaign_Log
SET RunStartTime_Part4=GETDATE()
WHERE ID=@MY_ID
-- PRINT 'Part4'
EXEC MI. CampaignResults_Calculate_Part4 @DatabaseName

-- Log that Store Procedure did not return Error
UPDATE Warehouse.MI.Campaign_Log
SET ErrorMessage=0
WHERE ID=@MY_ID

-- Log when Store Procedure finished running
UPDATE Warehouse.MI.Campaign_Log
SET RunEndTime=GETDATE()
WHERE ID=@MY_ID

END
