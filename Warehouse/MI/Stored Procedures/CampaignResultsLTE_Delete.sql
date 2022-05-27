-- =============================================
-- Author:		Dorota
-- Create date:	15/06/2015
-- =============================================

CREATE PROCEDURE MI.CampaignResultsLTE_Delete (@ClientServicesRef varchar(25), @StartDate DATE) AS -- -- unhide this row to modify SP
--DECLARE @ClientServicesRef varchar(25); SET @ClientServicesRef=?; DECLARE  @StartDate; SET @StartDate=? -- unhide this row to run code once

BEGIN 

-- Log when Store Procedure started running in CamapainResults_Log
INSERT INTO Warehouse.MI.Campaign_Log
(StoreProcedureName,  
Parameter_ClientServicesRef, Parameter_StartDate, 
RunByUser , RunStartTime)
SELECT 'CampaignResultsLTE_Delete', 
@ClientServicesRef, @StartDate, 
SYSTEM_USER, GETDATE()

-- Store RowID for curently running Store Procedure
DECLARE @MY_ID AS INT;
SET @MY_ID= (SELECT SCOPE_IDENTITY());

-- Delete rows from working tables
DELETE FROM Warehouse.MI.CampaignInternalResultsLTE_PureSales WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
DELETE FROM Warehouse.MI.CampaignInternalResultsLTE_Workings WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate

DELETE FROM Warehouse.MI.CampaignExternalResultsLTE_PureSales WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
DELETE FROM Warehouse.MI.CampaignExternalResultsLTE_Workings WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate

-- Delete rows from Final Results tables on Wave level
DELETE FROM Warehouse.MI.CampaignInternalResultsLTEFinalWave WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
DELETE FROM Warehouse.MI.CampaignInternalResultsLTEFinalWave_BespokeCell WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
DELETE FROM Warehouse.MI.CampaignInternalResultsLTEFinalWave_Segment WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
DELETE FROM Warehouse.MI.CampaignInternalResultsLTEFinalWave_SuperSegment WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
 
DELETE FROM Warehouse.MI.CampaignExternalResultsLTEFinalWave WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
DELETE FROM Warehouse.MI.CampaignExternalResultsLTEFinalWave_BespokeCell WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
DELETE FROM Warehouse.MI.CampaignExternalResultsLTEFinalWave_Segment WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
DELETE FROM Warehouse.MI.CampaignExternalResultsLTEFinalWave_SuperSegment WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate

-- Delete rows from Final Results tables on CSR level
DELETE FROM Warehouse.MI.CampaignInternalResultsLTEFinalCSR WHERE ClientServicesRef=@ClientServicesRef
DELETE FROM Warehouse.MI.CampaignInternalResultsLTEFinalCSR_BespokeCell WHERE ClientServicesRef=@ClientServicesRef
DELETE FROM Warehouse.MI.CampaignInternalResultsLTEFinalCSR_Segment WHERE ClientServicesRef=@ClientServicesRef
DELETE FROM Warehouse.MI.CampaignInternalResultsLTEFinalCSR_SuperSegment WHERE ClientServicesRef=@ClientServicesRef

DELETE FROM Warehouse.MI.CampaignExternalResultsLTEFinalCSR WHERE ClientServicesRef=@ClientServicesRef
DELETE FROM Warehouse.MI.CampaignExternalResultsLTEFinalCSR_BespokeCell WHERE ClientServicesRef=@ClientServicesRef
DELETE FROM Warehouse.MI.CampaignExternalResultsLTEFinalCSR_Segment WHERE ClientServicesRef=@ClientServicesRef
DELETE FROM Warehouse.MI.CampaignExternalResultsLTEFinalCSR_SuperSegment WHERE ClientServicesRef=@ClientServicesRef

-- Log that Store Procedure did not return Error
UPDATE Warehouse.MI.Campaign_Log
SET ErrorMessage=0
WHERE ID=@MY_ID

-- Log when Store Procedure finished running
UPDATE Warehouse.MI.Campaign_Log
SET RunEndTime=GETDATE()
WHERE ID=@MY_ID

END