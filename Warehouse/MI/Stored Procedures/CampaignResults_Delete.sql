-- =============================================
-- Author:		Dorota
-- Create date:	15/05/2015
-- =============================================

CREATE PROCEDURE MI.CampaignResults_Delete (@ClientServicesRef varchar(25), @StartDate DATE) AS -- -- unhide this row to modify SP
--DECLARE @ClientServicesRef varchar(25); SET @ClientServicesRef=?; DECLARE  @StartDate; SET @StartDate=? -- unhide this row to run code once

BEGIN 

-- Log when Store Procedure started running in CamapainResults_Log
INSERT INTO Warehouse.MI.Campaign_Log
(StoreProcedureName,  
Parameter_ClientServicesRef, Parameter_StartDate, 
RunByUser , RunStartTime)
SELECT 'CampaignResults_Delete', 
@ClientServicesRef, @StartDate, 
SYSTEM_USER, GETDATE()

-- Store RowID for curently running Store Procedure
DECLARE @MY_ID AS INT;
SET @MY_ID= (SELECT SCOPE_IDENTITY());

-- Delete LTE Results
EXEC MI.CampaignResultsLTE_Delete @ClientServicesRef, @StartDate

-- Delete rows from Spenders tables
DELETE FROM Warehouse.Relational.Campaign_History_Spenders 
FROM Warehouse.Relational.Campaign_History_Spenders s
INNER JOIN Warehouse.Relational.IronOffer_Campaign_HTM h ON h.IronOfferID=s.IronOfferID
WHERE h.ClientServicesRef=@ClientServicesRef AND s.SDate=@StartDate

DELETE FROM Warehouse.Relational.Campaign_History_UC_Spenders 
FROM Warehouse.Relational.Campaign_History_UC_Spenders s
INNER JOIN Warehouse.Relational.IronOffer_Campaign_HTM h ON h.IronOfferID=s.IronOfferID
WHERE h.ClientServicesRef=@ClientServicesRef AND s.SDate=@StartDate

-- Delete rows from working tables
DELETE FROM Warehouse.MI.CampaignInternalResults_AdjFactor WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
DELETE FROM Warehouse.MI.CampaignInternalResults_PureSales WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
DELETE FROM Warehouse.MI.CampaignInternalResults_Workings WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate

DELETE FROM Warehouse.MI.CampaignExternalResults_AdjFactor WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
DELETE FROM Warehouse.MI.CampaignExternalResults_PureSales WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
DELETE FROM Warehouse.MI.CampaignExternalResults_Workings WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate

-- Delete rows from Final Results tables on Wave level
DELETE FROM Warehouse.MI.CampaignInternalResultsFinalWave WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
DELETE FROM Warehouse.MI.CampaignInternalResultsFinalWave_BespokeCell WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
DELETE FROM Warehouse.MI.CampaignInternalResultsFinalWave_Segment WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
DELETE FROM Warehouse.MI.CampaignInternalResultsFinalWave_SuperSegment WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
 
DELETE FROM Warehouse.MI.CampaignExternalResultsFinalWave WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
DELETE FROM Warehouse.MI.CampaignExternalResultsFinalWave_BespokeCell WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
DELETE FROM Warehouse.MI.CampaignExternalResultsFinalWave_Segment WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
DELETE FROM Warehouse.MI.CampaignExternalResultsFinalWave_SuperSegment WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate

-- Delete rows from Final Results tables on CSR level
DELETE FROM Warehouse.MI.CampaignInternalResultsFinalCSR WHERE ClientServicesRef=@ClientServicesRef
DELETE FROM Warehouse.MI.CampaignInternalResultsFinalCSR_BespokeCell WHERE ClientServicesRef=@ClientServicesRef
DELETE FROM Warehouse.MI.CampaignInternalResultsFinalCSR_Segment WHERE ClientServicesRef=@ClientServicesRef
DELETE FROM Warehouse.MI.CampaignInternalResultsFinalCSR_SuperSegment WHERE ClientServicesRef=@ClientServicesRef

DELETE FROM Warehouse.MI.CampaignExternalResultsFinalCSR WHERE ClientServicesRef=@ClientServicesRef
DELETE FROM Warehouse.MI.CampaignExternalResultsFinalCSR_BespokeCell WHERE ClientServicesRef=@ClientServicesRef
DELETE FROM Warehouse.MI.CampaignExternalResultsFinalCSR_Segment WHERE ClientServicesRef=@ClientServicesRef
DELETE FROM Warehouse.MI.CampaignExternalResultsFinalCSR_SuperSegment WHERE ClientServicesRef=@ClientServicesRef

-- Log that Store Procedure did not return Error
UPDATE Warehouse.MI.Campaign_Log
SET ErrorMessage=0
WHERE ID=@MY_ID

-- Log when Store Procedure finished running
UPDATE Warehouse.MI.Campaign_Log
SET RunEndTime=GETDATE()
WHERE ID=@MY_ID

END