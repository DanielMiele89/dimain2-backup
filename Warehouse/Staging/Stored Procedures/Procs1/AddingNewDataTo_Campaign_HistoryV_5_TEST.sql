/*
Author:		Suraj Chahal
Date:		21/02/2013
Purpose:	Once offer email has been sent, Use this stored procedure to add the Selections for the New offer into the
		Warehouse.Relational.Campaign_History table. - Chunk Sized
Parameters:	Requires an table input

Update:		2016-09-02 SB - Needs simplifying as process is taking to long

*/

CREATE PROCEDURE [Staging].[AddingNewDataTo_Campaign_HistoryV_5_TEST]
	@TableName varchar(200)

AS


BEGIN

Truncate TABLE [Staging].[Campaign_History]

DECLARE @Qry nvarchar(MAX)
SET @Qry = '
	Insert INTO [Staging].[Campaign_History]
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

--Select @Qry
EXEC sp_executesql @Qry

Declare @RowNo int , @MaxRowNo int,@ChunkSize int

Set @RowNo = 1
Set @MaxRowNo = (Select Max(RowNo) From [Staging].[Campaign_History])
Set @ChunkSize = 500

While @RowNo <= @MaxRowNo
Begin
	Insert into Relational.Campaign_History
	Select  CompositeID, 
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
	From [Staging].[Campaign_History]
	Where RowNo Between @RowNo and @RowNo+(@ChunkSize-1)
	Set @RowNo = @RowNo+@ChunkSize
End
--SELECT @Qry

END