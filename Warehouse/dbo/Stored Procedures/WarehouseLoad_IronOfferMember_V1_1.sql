/*
Author:		Stuart Barnley	
Date:		07th February 2014
Purpose:	Incrementally load the IronOfferMember table in the Relational schema of the Warehouse database
			This version is for during the week to minimise processing time, we are not reloading anything 
			that has been loaded before (does not allow for change).
			
		
Update:		SB - 2017-07-22 - Amendment made to make sure new records don't break costraint	
*/
Create Procedure WarehouseLoad_IronOfferMember_V1_1
as
/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'Warehouseload_IronOfferMember_V1_1',
		TableSchemaName = 'Relational',
		TableName = 'IronOfferMember',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'A'
--Counts pre-population
DECLARE	@RowCount BIGINT
SET @RowCount = (SELECT COUNT(*) FROM Relational.IronOfferMember with (nolock))
--*************Select Getdate() as StartDate, 'Find Missing People - Start'*************--
-------------------------------------------------------------------------------------
------------See which customers already have records in  IronOfferMmber--------------
-------------------------------------------------------------------------------------
--Get a distinct list of all customers who already have some records in ironoffermember

if object_id('tempdb..#AlreadyPresent') is not null drop table #AlreadyPresent
Select Distinct CompositeID
Into #AlreadyPresent
From Relational.Ironoffermember with (nolock)
--Index temporary table due to size
create clustered index ixc_AP on #AlreadyPresent(CompositeID)

-------------------------------------------------------------------------------------
-----------------Find those people in the customer table not in IOM------------------
-------------------------------------------------------------------------------------
--Get a list of those customers that have no records in ironoffermember
if object_id('tempdb..#MissingCustomers') is not null drop table #MissingCustomers
Select c.CompositeID
Into #MissingCustomers
from Relational.Customer as c with (nolock)
left outer join #AlreadyPresent as ap
	on c.CompositeID = ap.CompositeID
Where ap.CompositeID is null
--*************Select Getdate() as StartDate, 'Find Missing People - End'*************--
-------------------------------------------------------------------------------------
--------------Find out datetime of last imported record in Warehouse IOM ------------
-------------------------------------------------------------------------------------
--*************Select Getdate() as StartDate, 'Find Last RecordID - Start'*************--
--Find the number of the last record in the table
Declare @LastRecord as int
Set @LastRecord = (
Select Max(iom.IronOfferMemberID)
from Relational.IronOfferMember as iom)

--Select @LastRecord
--*************Select Getdate() as StartDate, 'Find Last RecordID - End'*************--
-------------------------------------------------------------------------------------
------------------------Find records for previously unknown people-------------------
-------------------------------------------------------------------------------------
--Select Getdate() as StartDate, 'Insert Missing people data - Start'
insert into Relational.IronOfferMember
select	iom.ID as IronOfferMemberID,
		iom.IronOfferID,
		iom.CompositeID,
		iom.StartDate,
		iom.EndDate,
		iom.ImportDate
--Into #Unknowns
from SLC_Report.dbo.IronOfferMember as iom with (nolock)
Inner join #MissingCustomers as mc with (nolock)
	on iom.CompositeID = mc.CompositeID and iom.id <= @LastRecord
--*************Select Getdate() as StartDate, 'Insert Missing people data - End'*************--
-------------------------------------------------------------------------------------
--------------------------Find records loaded since last date------------------------
-------------------------------------------------------------------------------------
--*************Select Getdate() as StartDate, 'Insert New rows - Start'*************--
insert into Relational.IronOfferMember
select iom.ID as IronOfferMemberID,
		iom.IronOfferID,
		iom.CompositeID,
		iom.StartDate,
		iom.EndDate,
		iom.ImportDate
--into #NewLoads
from SLC_Report.dbo.IronOfferMember as iom with (nolock)
Inner join Relational.Customer as c with (nolock)
	on iom.CompositeID = c.CompositeID
left outer join Warehouse.relational.ironoffermember as i with (nolock)
	on	iom.IronOfferID = i.IronOfferID and
		iom.CompositeID = i.CompositeID and
		(iom.StartDate = i.startdate or (iom.Startdate is null and i.StartDate is null) )and
		(iom.EndDate = i.EndDate or (iom.EndDate is null and i.EndDate is null) )
Where	iom.ID > @LastRecord and
		i.IronOfferMemberID is null

--Select * from #NewLoads as nl
--inner join warehouse.Relational.IronOfferMember as iom
	--on nl.IronOfferMemberID = iom.IronOfferMemberID

--*************Select Getdate() as StartDate, 'Insert New rows - End'*************--
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'Warehouseload_IronOfferMember_V1_1' and
		TableSchemaName = 'Relational' and
		TableName = 'IronOfferMember' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  staging.JobLog_Temp
Set		TableRowCount = (Select COUNT(*) from Relational.IronOfferMember)-@RowCount
where	StoredProcedureName = 'Warehouseload_IronOfferMember_V1_1' and
		TableSchemaName = 'Relational' and
		TableName = 'IronOfferMember' and
		TableRowCount is null
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
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

--Delete from Warehouse.relational.ironoffermember
--Where ImportDate >= '2015-07-21'