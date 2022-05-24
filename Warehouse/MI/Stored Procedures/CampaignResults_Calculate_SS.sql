-- =============================================
-- Author:		Dorota
-- Create date:	15/05/2015
-- =============================================

CREATE PROCEDURE [MI].[CampaignResults_Calculate_SS] (@ClientServicesRef varchar(25)=NULL, @StartDate DATE=NULL, @DatabaseName NVARCHAR(400)='Sandbox') AS -- -- unhide this row to modify SP
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

-- Check if Results are already stored in working tables
IF (SELECT COUNT(*) FROM Warehouse.Relational.Campaign_History_Spenders s
    INNER JOIN Warehouse.Relational.IronOffer_Campaign_HTM h ON h.IronOfferID=s.IronOfferID
    WHERE h.ClientServicesRef=@ClientServicesRef AND s.SDate=@StartDate)>0

    OR (SELECT COUNT(*) FROM Warehouse.MI.CampaignInternalResults_AdjFactor WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate)>0
    OR (SELECT COUNT(*) FROM Warehouse.MI.CampaignInternalResults_PureSales WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate)>0
    OR (SELECT COUNT(*) FROM Warehouse.MI.CampaignInternalResults_Workings WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate)>0
    
    OR (SELECT COUNT(*) FROM Warehouse.Relational.Campaign_History_UC_Spenders s
    INNER JOIN Warehouse.Relational.IronOffer_Campaign_HTM h ON h.IronOfferID=s.IronOfferID
    WHERE h.ClientServicesRef=@ClientServicesRef AND s.SDate=@StartDate)>0

    OR (SELECT COUNT(*) FROM Warehouse.MI.CampaignExternalResults_AdjFactor WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate)>0
    OR (SELECT COUNT(*) FROM Warehouse.MI.CampaignExternalResults_PureSales WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate)>0
    OR (SELECT COUNT(*) FROM Warehouse.MI.CampaignExternalResults_Workings WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate)>0

BEGIN
    -- If already stored show error message 
    PRINT 'Calculations for ' + @ClientServicesRef +' starting ' + CAST(@StartDate AS VARCHAR) + ' are already stored in the Warehouse.MI.CampaignResults tables.
If the results need to be corrected/updated run Store Procedure MI.CampaignResults_Delete first.' 

    -- Log that Store Procedure returned Error
    UPDATE Warehouse.MI.Campaign_Log
    SET ErrorMessage=1
    WHERE ID=@MY_ID
END

-- Check if selected combination of ClientServicesRef and StartDate exists in Warehouse.MI.CampaignDetailsWave
-- Otherwise show error message 
ELSE IF  (SELECT COUNT(*) FROM Warehouse.MI.CampaignDetailsWave WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate)=0
    BEGIN
	       PRINT 'Wrong ClientServicesRef or StartDate selected (' + @ClientServicesRef +' starting ' + CAST(@StartDate AS VARCHAR) + ')'
		  
		  -- Log that Store Procedure returned Error
		  UPDATE Warehouse.MI.Campaign_Log
		  SET ErrorMessage=1
		  WHERE ID=@MY_ID

    END

---- Check if at leastt 1 control group exists
--ELSE IF (SELECT COUNT(*) FROM Warehouse.Relational.Campaign_History s
--    INNER JOIN Warehouse.Relational.IronOffer_Campaign_HTM h ON h.IronOfferID=s.IronOfferID
--    WHERE h.ClientServicesRef=@ClientServicesRef AND s.SDate=@StartDate AND s.Grp='Control')=0

--    AND (SELECT COUNT(*) FROM Warehouse.Relational.Campaign_History_UC s
--    INNER JOIN Warehouse.Relational.IronOffer_Campaign_HTM h ON h.IronOfferID=s.IronOfferID
--    WHERE h.ClientServicesRef=@ClientServicesRef AND s.SDate=@StartDate)=0
    
--    BEGIN 
--	   PRINT 'Neither Random nor Out of Programme Control Group was set up for ' + @ClientServicesRef +' starting ' + CAST(@StartDate AS VARCHAR)
	   
--	   -- Log that Store Procedure returned Error
--	   UPDATE Warehouse.MI.Campaign_Log
--	   SET ErrorMessage=1
--	   WHERE ID=@MY_ID

--    END

ELSE

BEGIN
    -- Otherwise measure campaign and store calculations in working tables

    -- Log when Part1 started running
    UPDATE Warehouse.MI.Campaign_Log
    SET RunStartTime_Part1=GETDATE()
    WHERE ID=@MY_ID
    --PRINT 'Part1'
	--IF @StartDate < '2016-06-23'
		EXEC MI. CampaignResults_Calculate_Part1_SSControl @ClientServicesRef, @StartDate, @DatabaseName
	--ELSE
	--	EXEC MI.CampaignResults_Calculate_Part1_SS @ClientServicesRef, @StartDate, @DatabaseName
	
    -- Log when Part2 started running
    UPDATE Warehouse.MI.Campaign_Log
    SET RunStartTime_Part2=GETDATE()
    WHERE ID=@MY_ID
   -- PRINT 'Part2'
    EXEC MI. CampaignResults_Calculate_Part2_SS @DatabaseName

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
END

-- Log when Store Procedure finished running
UPDATE Warehouse.MI.Campaign_Log
SET RunEndTime=GETDATE()
WHERE ID=@MY_ID

END