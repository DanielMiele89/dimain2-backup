/*
Author:		Suraj Chahal
Date:		21/02/2013
Purpose:	Once offer email has been sent, Use this stored procedure to add the Selections for the New offer into the
		Warehouse.Relational.Campaign_History table. - Chunk Sized
Parameters:	Requires an table input

*/

CREATE PROCEDURE [Staging].[AddingNewDataTo_Campaign_HistoryV_2]
	@TableName varchar(200),
	@HTM BIT

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
		'+
			CASE	WHEN @HTM = 1	THEN 'HTMID' 
				ELSE 'NULL'
			END +'					as HTMID,
		Grp,
		a.PartnerID,
		SDate = io.StartDate,
		EDate = io.EndDate,
		[Comm Type],
		io.IsTriggerOffer as IsGasTrigger,
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
INSERT INTO Warehouse.Relational.Campaign_History
SELECT	TOP	
	(@ChunkSize)
	CompositeID, 
	FanID,
	IronOfferID,
	HTMID,
	Grp,
	PartnerID,
	SDate,
	EDate,
	[Comm Type],
	IsGasTrigger,
	TriggerBatch
FROM #Temp1
WHERE CampaignHistoryID > @StartRow
ORDER BY CampaignHistoryID

SET @StartRow = (SELECT COUNT(1) FROM Warehouse.Relational.Campaign_History WHERE IronOfferID IN (SELECT IronOfferID FROM #Temp1))

END
'

--SELECT @Qry
EXEC sp_executesql @Qry


END