
/*
Author:		Suraj Chahal
Date:		06/01/2015
Purpose:	Once offer email has been sent, Use this stored procedure to add the Selections for the New offer into the
		Warehouse.Relational.Campaign_History table. - Chunk Sized
Parameters:	Requires an table input

*/

CREATE PROCEDURE [Staging].[AddingNewDataTo_Campaign_History_UC]
	@TableName varchar(200)

AS


BEGIN

DECLARE @Qry nvarchar(MAX)
SET @Qry = '


SELECT	ROW_NUMBER() over(order by CompositeID) as  CampaignHistoryID,
	*
INTO #Temp1
FROM
(
	SELECT	CompositeID, 
		FanID,
		OfferID	as IronOfferID,
		HTMID,
		a.PartnerID,
		SDate = io.StartDate,
		EDate = io.EndDate,
		TriggerBatch
	FROM  ' +' '+ @Tablename +'  a
	INNER JOIN slc_report.dbo.IronOffer io
			on a.OfferID = io.id
) as a




/*--------------------------------------------------------------------------------------------------------------
----------------------Insert Targetted Offers to Warehouse.Relational.Campaign_History--------------------------
---------------------------------------------------------------------------------------------------------------*/
select count(1)from #Temp1
/*------------------------------------------------------------------------*/
---------------------------Declare the variables---------------------------
/*------------------------------------------------------------------------*/
DECLARE @StartRow INT,
	@ChunkSize INT
SET @StartRow = 0
SET @ChunkSize = 500000

/*------------------------------------------------------
-----------------------Insert---------------------------
-------------------------------------------------------*/
WHILE EXISTS (SELECT 1 FROM #Temp1 WHERE CampaignHistoryID > @StartRow)
BEGIN
---------------------------------------------
INSERT INTO Warehouse.Relational.Campaign_History_UC
SELECT	TOP	
	(@ChunkSize)
	CompositeID, 
	FanID,
	IronOfferID,
	HTMID,
	PartnerID,
	SDate,
	EDate,
	TriggerBatch
FROM #Temp1
WHERE CampaignHistoryID > @StartRow
ORDER BY CampaignHistoryID

SET @StartRow = (SELECT COUNT(1) FROM Warehouse.Relational.Campaign_History_UC WHERE IronOfferID IN (SELECT IronOfferID FROM #Temp1))

END


SELECT	IronOfferID,
	COUNT(*) as RowsAdded 
FROM Warehouse.Relational.Campaign_History_UC
WHERE IronOfferID IN (SELECT DISTINCT OfferID FROM ' +' '+ @Tablename +')
GROUP BY IronOfferID
ORDER BY IronOfferID
'

--SELECT @Qry
EXEC sp_executesql @Qry


END
