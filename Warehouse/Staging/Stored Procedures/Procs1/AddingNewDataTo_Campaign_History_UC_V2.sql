
/*
Author:		Suraj Chahal
Date:		06/01/2015
Purpose:	Once offer email has been sent, Use this stored procedure to add the Selections for the New offer into the
		Warehouse.Relational.Campaign_History table. - Chunk Sized
Parameters:	Requires an table input

*/

CREATE PROCEDURE [Staging].[AddingNewDataTo_Campaign_History_UC_V2]
	@TableName varchar(200)

AS


BEGIN

	DECLARE @Qry nvarchar(MAX)
	SET @Qry = '


	/*------------------------------------------------------
	-----------------------Insert---------------------------
	-------------------------------------------------------*/
	---------------------------------------------
	INSERT INTO Warehouse.Relational.Campaign_History_UC
	SELECT
		f.CompositeID, 
		FanID,
		OfferID,
		HTMID,
		PartnerID,
		StartDate,
		EndDate,
		TriggerBatch
	FROM '+@TableName+' as t
	inner join slc_report.dbo.fan as f with (nolock)
		on t.FanID = f.ID
	'
	--SELECT @Qry
	EXEC sp_executesql @Qry

End
