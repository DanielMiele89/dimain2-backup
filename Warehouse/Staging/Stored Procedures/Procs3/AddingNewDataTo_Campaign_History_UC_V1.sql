
/*
Author:		Suraj Chahal
Date:		06/01/2015
Purpose:	Once offer email has been sent, Use this stored procedure to add the Selections for the New offer into the
		Warehouse.Relational.Campaign_History table. - Chunk Sized
Parameters:	Requires an table input

*/

CREATE PROCEDURE [Staging].[AddingNewDataTo_Campaign_History_UC_V1]
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
	SELECT	f.CompositeID, 
		a.FanID,
		a.OfferID	as IronOfferID,
		a.HTMID,
		a.PartnerID,
		a.StartDate as SDate,
		a.EndDate as EDate,
		a.TriggerBatch
	FROM  ' +' '+ @Tablename +'  a
	inner join slc_report.dbo.fan as f with (nolock)
		on a.FanID = f.ID
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