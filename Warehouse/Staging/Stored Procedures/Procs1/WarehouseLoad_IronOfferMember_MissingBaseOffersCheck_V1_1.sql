/*
	Author:			Stuart Barnley
	Date:			30-04-2014

	Description:	Add entries to IronOfferMember for base entries that are missing due to
					activation, deactivation re-activation 
*/
Create Procedure [Staging].[WarehouseLoad_IronOfferMember_MissingBaseOffersCheck_V1_1]
as
/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'WarehouseLoad_IronOfferMember_MissingBaseOffersCheck_V1',
		TableSchemaName = 'Relational',
		TableName = 'IronOfferMember',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'A'

------------------------------------------------------------------------------------------
--********************************List of Customers*************************************--
------------------------------------------------------------------------------------------
if object_id('tempdb..#CB') is not null drop table #CB
select	FaniD,
		CompositeID,
		ClubID
Into #CB
from Relational.Customer with (nolock)
create clustered index ixc_CB on #CB(Compositeid)
------------------------------------------------------------------------------------------
--********************************List of Base Offers***********************************--
------------------------------------------------------------------------------------------
if object_id('tempdb..#BaseOffers') is not null drop table #BaseOffers
select Distinct		OfferID,
					ClubID,
					ROW_NUMBER() OVER (ORDER BY OfferID,ClubID) AS RowNumber
Into #BaseOffers
From Relational.Partneroffers_Base with (nolock)
create clustered index ixc_BO on #BaseOffers(OfferID)
------------------------------------------------------------------------------------------
--************************List of missing Base Offers entries***************************--
------------------------------------------------------------------------------------------
Declare @OfferID int,@ClubID int,@RowNo int, @RowMax int

Set @RowNo = 1
Set @RowMax = (Select Max(RowNumber) from #BaseOffers)

--Create table to store entries in
if object_id('tempdb..#MissingOffers') is not null drop table #MissingOffers
Create Table #MissingOffers (CompositeID bigint,IronOfferID int)

--Loop around to get a list of all people missing from each base offer
While @RowNo <= @RowMax
Begin
	Set @OfferID = (Select OfferID from #BaseOffers where RowNumber = @RowNo)
	Set @ClubID  = (Select ClubID  from #BaseOffers where RowNumber = @RowNo)
	--Select @OfferID,@ClubID
	Insert into #MissingOffers
	select	CompositeID, 
			@OfferID as IronOfferID
	from #CB as c
	where	CompositeID not in  (	select CompositeID 
									from  Relational.IronOfferMember with (nolock) 
									where ironofferid=@OfferID
								)
			and c.ClubID = @ClubID
	Set @RowNo = @RowNo+1
End

create clustered index ixc_MO on #MissingOffers(CompositeID)

Declare @Rows int
Set @Rows = (select Count(*) from Relational.IronOfferMember with (nolock))
------------------------------------------------------------------------------------------
--*********************Add extra Entries to Iron Offer member***************************--
------------------------------------------------------------------------------------------
--Find those people who were in the base offers and add the entries from SLC_report
Insert into Relational.IronOfferMember
select	--iom.ID as IronOfferMemberID,
		iom.IronOfferID,
		iom.CompositeID,
		iom.StartDate,
		iom.EndDate,
		iom.ImportDate
from SLC_Report.dbo.IronOfferMember as iom with (nolock)
Inner join #MissingOffers as mc with (nolock)
	on	iom.CompositeID = mc.CompositeID and 
		iom.IronOfferID = mc.IronOfferID
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'WarehouseLoad_IronOfferMember_MissingBaseOffersCheck_V1' and
		TableSchemaName = 'Relational' and
		TableName = 'IronOfferMember' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  staging.JobLog_Temp
Set		TableRowCount = (Select COUNT(*) from Relational.IronOfferMember with (nolock))-@Rows
where	StoredProcedureName = 'WarehouseLoad_IronOfferMember_MissingBaseOffersCheck_V1' and
		TableSchemaName = 'Relational' and
		TableName = 'IronOfferMember' and
		TableRowCount is null


Insert into staging.JobLog
select [StoredProcedureName],
	[TableSchemaName],
	[TableName],
	[StartDate],
	[EndDate],
	[TableRowCount],
	[AppendReload]
from staging.JobLog_Temp

TRUNCATE TABLE staging.JobLog_Temp