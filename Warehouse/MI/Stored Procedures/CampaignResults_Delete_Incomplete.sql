-- =============================================
-- Author:		Dorota
-- Create date:	15/05/2015
-- =============================================

CREATE PROCEDURE [MI].[CampaignResults_Delete_Incomplete] (
    @ClientServicesRef varchar(25)
    , @StartDate DATE
) AS -- -- unhide this row to modify SP

BEGIN 

-- Log when Store Procedure started running in CamapainResults_Log
INSERT INTO Warehouse.MI.Campaign_Log
(StoreProcedureName,  
Parameter_ClientServicesRef, Parameter_StartDate, 
RunByUser , RunStartTime)
SELECT 'CampaignResults_Delete_Incomplete', 
@ClientServicesRef, @StartDate, 
SYSTEM_USER, GETDATE()

-- Store RowID for curently running Store Procedure
DECLARE @MY_ID AS INT;
SET @MY_ID= (SELECT SCOPE_IDENTITY());


-- Delete rows from working tables
DELETE FROM Warehouse.MI.CampaignInternalResults_AdjFactor_Incomplete WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
DELETE FROM Warehouse.MI.CampaignInternalResults_PureSales_Incomplete WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
DELETE FROM Warehouse.MI.CampaignInternalResults_Workings_Incomplete WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate

DELETE FROM Warehouse.MI.CampaignExternalResults_AdjFactor_Incomplete WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
DELETE FROM Warehouse.MI.CampaignExternalResults_PureSales_Incomplete WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
DELETE FROM Warehouse.MI.CampaignExternalResults_Workings_Incomplete WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate

-- Delete rows from Final Results tables on Wave level
DELETE FROM Warehouse.MI.CampaignInternalResultsFinalWave_Incomplete WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
DELETE FROM Warehouse.MI.CampaignInternalResultsFinalWave_BespokeCell_Incomplete WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
DELETE FROM Warehouse.MI.CampaignInternalResultsFinalWave_Segment_Incomplete WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
DELETE FROM Warehouse.MI.CampaignInternalResultsFinalWave_SuperSegment_Incomplete WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
 
DELETE FROM Warehouse.MI.CampaignExternalResultsFinalWave_Incomplete WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
DELETE FROM Warehouse.MI.CampaignExternalResultsFinalWave_BespokeCell_Incomplete WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
DELETE FROM Warehouse.MI.CampaignExternalResultsFinalWave_Segment_Incomplete WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
DELETE FROM Warehouse.MI.CampaignExternalResultsFinalWave_SuperSegment_Incomplete WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate

-- Delete rows from Final Results tables on CSR level
DELETE FROM Warehouse.MI.CampaignInternalResultsFinalCSR_Incomplete WHERE ClientServicesRef=@ClientServicesRef
DELETE FROM Warehouse.MI.CampaignInternalResultsFinalCSR_BespokeCell_Incomplete WHERE ClientServicesRef=@ClientServicesRef
DELETE FROM Warehouse.MI.CampaignInternalResultsFinalCSR_Segment_Incomplete WHERE ClientServicesRef=@ClientServicesRef
DELETE FROM Warehouse.MI.CampaignInternalResultsFinalCSR_SuperSegment_Incomplete WHERE ClientServicesRef=@ClientServicesRef

DELETE FROM Warehouse.MI.CampaignExternalResultsFinalCSR_Incomplete WHERE ClientServicesRef=@ClientServicesRef
DELETE FROM Warehouse.MI.CampaignExternalResultsFinalCSR_BespokeCell_Incomplete WHERE ClientServicesRef=@ClientServicesRef
DELETE FROM Warehouse.MI.CampaignExternalResultsFinalCSR_Segment_Incomplete WHERE ClientServicesRef=@ClientServicesRef
DELETE FROM Warehouse.MI.CampaignExternalResultsFinalCSR_SuperSegment_Incomplete WHERE ClientServicesRef=@ClientServicesRef

-- Log that Store Procedure did not return Error
UPDATE Warehouse.MI.Campaign_Log
SET ErrorMessage=0
WHERE ID=@MY_ID

-- Log when Store Procedure finished running
UPDATE Warehouse.MI.Campaign_Log
SET RunEndTime=GETDATE()
WHERE ID=@MY_ID

END