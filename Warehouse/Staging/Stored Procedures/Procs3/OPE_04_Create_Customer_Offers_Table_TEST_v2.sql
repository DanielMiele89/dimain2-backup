--Select * 
--from Staging.OPE_Offers_Weighted
CREATE Procedure [Staging].[OPE_04_Create_Customer_Offers_Table_TEST_v2] (@EmailDate as date)
As
/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/
Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'OPE_04_Create_Customer_Offers_Table',
		TableSchemaName = 'Staging',
		TableName = 'OPE_Members',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'R'
/*--------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------*/
Declare	@RowNo int, 
		@MaxRow int,
		@IronOfferID int,
		@HTMID int,
		@PartnerID int,
		@FanID int,
		@ChunkSize int
		
Set @RowNo = 1
Set @ChunkSize = 5000
-----------------------------------------------------------------------------------------
--------------------------------Create Customer Table------------------------------------*******-Limited for Testing
-----------------------------------------------------------------------------------------
if object_id('tempdb..#Customer') is not null drop table #Customer
Select --top 150000 
FanID,CompositeID,ROW_NUMBER() OVER (ORDER BY FanID) AS RowNumber
Into #Customer
From Relational.Customer as c
Where MarketableByEmail = 1
Order by FanID
-----------------------------------------------------------------------------------------
--------------------------------Create list of above base offers ------------------------
-----------------------------------------------------------------------------------------
if object_id('tempdb..#Offers_AB') is not null drop table #Offers_AB
Select	w.*,
		Case
			When sow.PartnerID is not null then 1
			Else 0
		End SOW
Into #Offers_AB
From Staging.OPE_Offers_Weighted as w
Left Outer join Staging.OPE_SOWRunDate as sow
	on w.PartnerID = SOW.PartnerID
Where	w.BaseOffer = 0
		
		--select * from #Offers_AB
		--Where IronOfferID = 6889
----------------------------------------------------------------------------------------
--------------------------------Import Members of all offers-----------------------------
-----------------------------------------------------------------------------------------
Set @MaxRow = (Select MAX(RowNumber) from #Customer)

if object_id('tempdb..#Members') is not null drop table #Members
Create Table #Members			(	ID int identity (1,1), 
									FanID int, 
									IronOfferID int, 
									HTMID int, 
									TotalScore int,
									RowNo int,
									IOM bit)



if object_id('Staging.OPE_Members') is not null drop table Staging.OPE_Members
Create Table Staging.OPE_Members (	ID int identity (1,1), 
									FanID int, 
									IronOfferID int, 
									HTMID int, 
									InitialSlot Int,
									CurrentSlot int,
									FinalSlot int, 
									IOM bit, 
									[Status] tinyint)
While @RowNo <= @MaxRow
Begin
			
	--Insert into Staging.OPE_Members
	Insert Into #Members
	Select	FanID,
			IronOfferID,
			HTMID,
			TotalScore,
			RowNumber,
			IOM
			
	From
	(Select	a.FanID,
			a.IronOfferID,
			a.HTMID,
			a.TotalScore,
			a.RowNumber,
			MAX(IOM) as IOM	
	From
	(	Select	Distinct
				c.FanID,
				iom.IronOfferID,
				coalesce(SOW.HTMID,0) as HTMID,
				w.TotalScore,
				w.RowNumber,
				1 as IOM
		From Relational.OPE_IronOfferMember_Test as iom
		inner join #Customer as c
			on iom.CompositeID = c.CompositeID
		inner join #Offers_AB as W
			on iom.IronOfferID = W.IronOfferID
		Left Outer join Relational.ShareOfWallet_Members as sow
			on	c.FanID = sow.FanID and
				sow.PartnerID = w.PartnerID and
				sow.HTMID = w.HTMID and
				(sow.EndDate is NULL or sow.EndDate >= @EmailDate) and
				sow.StartDate <= @EmailDate
		Where	c.RowNumber >= @RowNo and  
				c.RowNumber < @RowNo+@ChunkSize and
				((sow.HTMID is not null and w.SOW = 1)  or (sow.HTMID is null and 
						w.SOW = 0 and w.HTMID = 0)) 
		Union All
	
		Select	c.FanID,
				iom.IronOfferID,
				coalesce(SOW.HTMID,0) as HTMID,
				w.TotalScore,
				w.RowNumber,
				0 as IOM
		From Staging.NominatedOfferMember_Prospects as iom
		inner join #Customer as c
			on iom.CompositeID = c.CompositeID
		inner join #Offers_AB as W
			on iom.IronOfferID = W.IronOfferID
		Left Outer join Relational.ShareOfWallet_Members as sow
			on	c.FanID = sow.FanID and
				sow.PartnerID = w.PartnerID and
				sow.HTMID = w.HTMID and
				(sow.EndDate is NULL or sow.EndDate >= @EmailDate) and
				sow.StartDate <= @EmailDate
		inner join Relational.IronOffer as i
			on	iom.IronOfferID = i.IronOfferID and
				i.StartDate >= @EmailDate
		Where	c.RowNumber >= @RowNo and
				c.RowNumber < @RowNo+@ChunkSize and
				((sow.HTMID is not null and w.SOW = 1)  or (sow.HTMID is null and 
						w.SOW = 0 and w.HTMID = 0)) 
	) as a
	Group By a.FanID,a.IronOfferID,a.HTMID,a.TotalScore,a.RowNumber
	) as a
	Order by FanID
	
	if object_id('tempdb..#TPO') is not null drop table #TPO
	Select FanID,PartnerID,Max(TotalScore) as MaxScore
	Into #TPO
	From #Members as m
	inner join Relational.IronOffer as i
		on m.IronOfferID = i.IronOfferID
	Group by FanID,PartnerID
		Having COUNT(*) > 1
	
	Delete from #Members
	From #Members as m
	inner join Relational.IronOffer as i
		on m.IronOfferID = i.IronOfferID
	inner join #TPO as t
		on m.FanID = t.FanID
	Where	m.TotalScore < t.MaxScore and
			i.PartnerID = t.PartnerID
	
	Insert into Staging.OPE_Members
	Select	FanID, 
			IronOfferID, 
			HTMID, 
			ROW_NUMBER() OVER(PARTITION BY FanID ORDER BY RowNo) AS Slot,
			ROW_NUMBER() OVER(PARTITION BY FanID ORDER BY RowNo) AS CurrentSlot,
			Cast(NULL as int) as FinalSlot, 
			IOM, 
			0 as [Status]
	From #Members
	
	Truncate table #Members
	
	Set @RowNo = @RowNo+@Chunksize
End
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'OPE_04_Create_Customer_Offers_Table' and
		TableSchemaName = 'Staging' and
		TableName = 'OPE_Members' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		TableRowCount = (Select Count(*) from Staging.OPE_Members)
where	StoredProcedureName = 'OPE_04_Create_Customer_Offers_Table' and
		TableSchemaName = 'Staging' and
		TableName = 'OPE_Members' and
		TableRowCount is null

/*--------------------------------------------------------------------------------------------------
------------------------------------------Add entry in JobLog Table --------------------------------
----------------------------------------------------------------------------------------------------*/
Insert into staging.JobLog
select [StoredProcedureName],
	[TableSchemaName],
	[TableName],
	[StartDate],
	[EndDate],
	[TableRowCount],
	[AppendReload]
from staging.JobLog_Temp
/*--------------------------------------------------------------------------------------------------
------------------------------------------Truncate JobLog temporary Table --------------------------
----------------------------------------------------------------------------------------------------*/
Truncate Table staging.JobLog_Temp