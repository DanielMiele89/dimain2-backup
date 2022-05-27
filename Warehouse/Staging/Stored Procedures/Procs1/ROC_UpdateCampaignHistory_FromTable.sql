/*
	
	Author:			Stuart Barnley

	Date:			9th December 2015

	Purpose:		To update ROC_CampaignHistory with members from a table


*/

CREATE Procedure Staging.ROC_UpdateCampaignHistory_FromTable
						 @TableName varchar(250)
as
-----------------------------------------------------------------------------
-----------------See if the data already exists in the table-----------------
-----------------------------------------------------------------------------
Declare @Qry nvarchar(Max)
Declare @DataAlreadyPresent table (AlreadyPresent bit)

--Set @TableName = 'Sandbox.[Stuart].[HalfordsSelection_ROC]'

Set @Qry = '
				Select Distinct 1
				from '+@TableName+' as a
				inner join Relational.ROC_WaveDates as c
					on  a.StartDate = c.StartDate
				inner join [Relational].[ROC_CampaignHistory] as b
					on	a.FanID = b.FanID and
						a.IronOfferID = b.IronOfferID and
						c.ID = b.WaveDatesID
		
			'
Insert into @DataAlreadyPresent
Exec SP_ExecuteSQL @Qry

IF (Select Count(*) from @DataAlreadyPresent) = 0

-----------------------------------------------------------------------------
-----------------------Find a list of the IronOfferIDs-----------------------
-----------------------------------------------------------------------------
Begin
	if object_id('tempdb..#Offers') is not null drop table #Offers
	Create Table #Offers (IronOfferID int, RowNo int, Primary Key(RowNo))
	Set @Qry = '
					Insert Into #Offers
					Select IronofferID,
							ROW_NUMBER() OVER (ORDER BY IronOfferID Asc) AS RowNo
					From
					(
						Select Distinct IronOfferID 
						from '+@TableName +' 
					) as a
	' 
	Exec sp_executeSQL @Qry

-----------------------------------------------------------------------------
---------------For each IronOfferID insert the member records----------------
-----------------------------------------------------------------------------

	Declare @RowNo int, @MaxRowNo int,@IronOfferID int

	Set @RowNo = 1
	Set @MaxRowNo = (Select Max(RowNo) from #Offers)

	While @RowNo <= @MaxRowNo
	Begin
			Set @IronOfferID = (Select IronOfferID from #Offers where RowNo = @RowNo)
			
			Set @qry = '
			Insert into [Relational].[ROC_CampaignHistory] 
			Select	a.FanID,
					i.PartnerID,
					i.ID as IronOfferID,
					a.IsControl,
					NULL as ClientServicesRef,
					a.SegmentID,
					w.ID as WavedatesID
			From '+@TableName+' as a
			inner join slc_report.dbo.IronOffer as i
				on A.IronOfferID = I.ID
			inner join Relational.ROC_WaveDates as w
				on a.StartDate = w.StartDate
			Where IronOfferID = '+Cast(@IronOfferID as varchar(8))+'
			'
			Exec sp_ExecuteSQL @Qry
			Set @RowNo = @RowNo + 1
	End
End 