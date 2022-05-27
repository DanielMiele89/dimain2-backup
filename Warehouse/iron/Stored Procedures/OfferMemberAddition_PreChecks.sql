/*
	Author:			Stuart Barnley
	
	Date:			2016-02-12
	
	Purpose:		This checks to make sure all new offers have an associated member selection,
					it also checks if a selection has 0 IronOfferIDs or if they point to an 
					inappropriate offer.

	Update:			N/A


*/

Create Procedure Iron.OfferMemberAddition_PreChecks (@SDate Date)
as

Declare		@StartDate Date,
			@EndRow int,
			@RowNo int,
			@TableName varchar(200),
			@Qry nvarchar(max)

Set @RowNo = (
				Select MIN(TableID) 
				From Warehouse.Relational.NominatedOfferMember_TableNames
			  )
Set @EndRow = (	
				Select Max(TableID) 
				From Warehouse.Relational.NominatedOfferMember_TableNames
			   )
			   
Set @StartDate = @SDate  --- Turn parameter into internal variable to avoid possible speed issues


----------------------------------------------------------------------------------------------
-------------Create and Populate a table of offers goiung live on defined date----------------
----------------------------------------------------------------------------------------------
if object_id('tempdb..#Offers') is not null drop table #Offers

Create Table #Offers (
						IronOfferID int, 
						Primary Key (IronOfferID)
					  )

--Pull a list of all RBSG offers going live on defined date
Insert Into #Offers
Select	Distinct 
		i.ID as IronOfferID
from	SLC_Report..IronOffer as i
inner join SLC_Report..IronOfferClub as ioc
		on i.ID = ioc.IronOfferID
Where	i.StartDate = @StartDate and
		ioc.ClubID in (132,138)

----------------------------------------------------------------------------------------------
-----------Create and Populate a table of OfferIDs fullfilled in selection Tables-------------
----------------------------------------------------------------------------------------------
if object_id('tempdb..#SelectionOffers') is not null drop table #SelectionOffers

Create Table #SelectionOffers (
								IronOfferID int,
								TableID smallint,
								Primary Key (IronOfferID)
							   )

if object_id('tempdb..#SelectionTables') is not null drop table #SelectionTables
Create Table #SelectionTables (
								[Comment] varchar(250),
								Primary Key ([Comment])
							  )
--Go through all offer selection tables created and put together a distinct list of IronOfferIDs
While @RowNo <= @EndRow
Begin
	Set @TableName = (	
						Select TableName 
						From Warehouse.Relational.NominatedOfferMember_TableNames 
						Where TableID = @RowNo
					  )
	Set @Qry = '
				if object_id('''+@TableName+''') is not null
				Begin
					Insert into #SelectionOffers
					Select	Distinct 
							OfferID as IronOfferID,
							'+Cast(@RowNo as varchar)+'
					From '+@TableName+' with (nolock)
					
					Insert into #SelectionTables
					Select '''+@TableName+' Imported''
				End
				Else
				Begin
					Insert into #SelectionTables
					Select '''+@TableName+ ' not found''
				End 
				'
	Exec sp_executeSQL @Qry

	Set @RowNo = @RowNo+1
End

------------------------------------------------------------------------------------------
-------------------------------Look for rows with zero OfferID----------------------------
------------------------------------------------------------------------------------------
Select	so.TableID,
		a.TableName,
		IronOfferID,
		'Offers With Zero IronOfferID' as [Type]
from #SelectionOffers as so
inner join Warehouse.Relational.NominatedOfferMember_TableNames as a
	on so.TableID = a.TableID
Where so.IronOfferID <= 0
Union All
Select	so.TableID,
		a.TableName,
		so.IronOfferID,
		'Offers not going live this week' as [Type]
from #SelectionOffers as so
Left Outer join #Offers as o
	on so.IronOfferID = o.IronOfferID
inner join Warehouse.Relational.NominatedOfferMember_TableNames as a
	on so.TableID = a.TableID
Where	o.IronOfferID is null and
		so.IronOfferID > 0
Union All		
Select	0 as TableID,
		'Not Found' as TableName,
		o.IronOfferID,
		'Offer IDs not found in any selection file' as [Type]
From #Offers as o
Left Outer Join #SelectionOffers as so
	on o.IronOfferID = so.IronOfferID
Where so.IronOfferID is null

Select * from #SelectionTables