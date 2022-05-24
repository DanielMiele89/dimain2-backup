/*

	Author:		Stuart Barnley

	Date:		28th December 2017

	Purpose:	Some customers will have been added to certain base offers before they activate therefore 
				the process retreives any missing memberships and adds them

*/

CREATE Procedure [Staging].[WarehouseLoad_IronOfferMembers_LoadOldMemberships] (@StartDate date,@EndDate Date)
With Execute as Owner
as

Declare @SDate date = @StartDate,
		@EDate date = @EndDate
------------------------------------------------------------------------------------------------------------------------
----------------------------------------Write entry to JobLog_Temp Table------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'WarehouseLoad_IronOfferMembers_LoadOldMemberships',
		TableSchemaName = 'Relational',
		TableName = 'IronofferMember',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'A'

------------------------------------------------------------------------------------
--------------Create a table of customers activated between date range--------------
------------------------------------------------------------------------------------

if object_id('tempdb..#Customers') is not null drop table #Customers
Select CompositeID
Into #Customers
From Relational.Customer as c  with (nolock)
Where ActivatedDate Between @SDate and @EDate

Create Clustered index cix_Customers_CompositeID on #Customers (CompositeID)

------------------------------------------------------------------------------------
----------------------------Create a table of Memberships---------------------------
------------------------------------------------------------------------------------
if object_id('tempdb..#Memberships') is not null drop table #Memberships
Select i.*
Into #Memberships
From #Customers as c
inner join SLC_report.dbo.IronofferMember as i with (nolock)
	on c.CompositeID = i.CompositeID

Create Clustered index cix_Memberships_etc on #Memberships (CompositeID,IronofferID,StartDate)


------------------------------------------------------------------------------------------------------------------------
------------------------------------------------Create columnstore Index------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

CREATE NONCLUSTERED COLUMNSTORE INDEX [CSX_IronOfferMember_All] ON [Relational].[IronOfferMember] ([IronOfferID], [CompositeID], [StartDate], [EndDate], [ImportDate])


------------------------------------------------------------------------------------
--------------------------Create a table of Missing Memberships---------------------
------------------------------------------------------------------------------------
if object_id('tempdb..#Missing') is not null drop table #Missing
Select m.*
Into #Missing
From #Memberships as m
left outer join Relational.IronofferMember as i with (nolock)
	on	m.CompositeID = i.CompositeID and
		m.IronOfferID = i.IronOfferID and
		m.StartDate = m.StartDate
Where i.CompositeID is null

------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------Drop columnstore Index-------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

DROP INDEX [CSX_IronOfferMember_All] ON [Relational].[IronOfferMember]

------------------------------------------------------------------------------------
---------------Insert into Warehouse.relational.IronOfferMember---------------------
------------------------------------------------------------------------------------
Declare @RowCount int

Insert into Relational.IronofferMember (IronOfferID,CompositeID,StartDate,EndDate,ImportDate)
Select IronOfferID,CompositeID,StartDate,EndDate,ImportDate
From #Missing
Where IsControl = 0
Set @RowCount = @@ROWCOUNT

------------------------------------------------------------------------------------------------------------------------
------------------------------------Update entry in JobLog_Temp Table with End Date-------------------------------------
------------------------------------------------------------------------------------------------------------------------
UPDATE staging.JobLog_Temp
SET		EndDate = GETDATE(),
		TableRowCount = @RowCount
WHERE	StoredProcedureName = 'WarehouseLoad_IronOfferMembers_LoadOldMemberships' 
	AND TableSchemaName = 'Relational'
	AND TableName = 'IronofferMember' 
	AND EndDate IS NULL