/*
Author:		Suraj Chahal
Date:		21/02/2013
Purpose:	Once offer email has been sent, Use this stored procedure to add the Selections for the New offer into the
		Warehouse.Relational.Campaign_History table. - Chunk Sized
Parameters:	Requires an table input

Update:		2016-09-02 SB - Needs simplifying as process is taking to long

*/

Create PROCEDURE [Staging].[AddingNewDataTo_Campaign_HistoryV_4]
	@TableName varchar(200)

AS


BEGIN

DECLARE @Qry nvarchar(MAX)
SET @Qry = '


Insert INTO [Relational].[Campaign_History]
	SELECT	
		a.CompositeID, 
		a.FanID,
		a.OfferID	as IronOfferID,
		NULL as HTMID,
		a.Grp,
		a.PartnerID,
		a.StartDate as SDate,
		a.EndDate as EDate,
		[Comm Type],
		io.IsTriggerOffer as IsGasTrigger,
		TriggerBatch
	FROM  ' +' '+ @Tablename +'  a
	INNER JOIN slc_report.dbo.IronOffer io
			on a.OfferID = io.id
'

--SELECT @Qry
EXEC sp_executesql @Qry


END