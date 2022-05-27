/*

	Author:		Stuart Barnley

	Date:		28th December 2017

	Purpose:	When the number of rows to load is Large then this will load them

*/

CREATE Procedure [Staging].[WarehouseLoad_IronOfferMembers_DailyBulkLoad] (@DataDate datetime)
With Execute as Owner
as

Declare @SDate Datetime = @DataDate,
		@EDate Datetime = Dateadd(day,1,@DataDate),
		@time DATETIME,
		@msg VARCHAR(2048)

------------------------------------------------------------------------------------------------------------------------
----------------------------------------Write entry to JobLog_Temp Table------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'WarehouseLoad_IronOfferMembers_DailyBulkLoad',
		TableSchemaName = 'Relational',
		TableName = 'IronofferMember',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'A'
		
-------------------------------------------------------------------------------------------
---------------------------------Create Table of Customers---------------------------------
-------------------------------------------------------------------------------------------
SELECT @msg = 'Created #Customers Table - Start'
EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

if object_id('tempdb..#Customers') is not null drop table #Customers
Select CompositeID
Into #Customers
From Relational.Customer

Create clustered index cix_Customers_CompositeID on #Customers (CompositeID) 

SELECT @msg = 'Created #Customers Table - End'
EXEC Staging.oo_TimerMessage @msg, @time OUTPUT
-------------------------------------------------------------------------------------------
----------------Find all offers with entries created on the date requested-----------------
-------------------------------------------------------------------------------------------
SELECT @msg = 'Created #Offers Table - Start'
EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

Select	IronOfferID,
		ROW_NUMBER() OVER(ORDER BY IronOfferID ASC) AS RowNo
Into #Offers
From (	
		Select Distinct IronOfferID
		From #Customers as c
		inner join slc_report.dbo.ironoffermember as iom
			on	c.CompositeID = iom.CompositeID and
				iom.ImportDate >= @SDate and 
				iom.ImportDate <  @EDate
	 ) as a

Create Clustered index cix_Offers_RowNo on #Offers (RowNo)

SELECT @msg = 'Created #Offers Table - End'
EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

--------------------------------------------------------------------------------------------
-----------------------------------Drop columnsotre Index-----------------------------------
--------------------------------------------------------------------------------------------

SELECT @msg = 'Drop ColumnStore Index - Start'
EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

DROP INDEX [CSX_IronOfferMember_All] ON [Relational].[IronOfferMember]

--Declare @DisableIndex nvarchar(max)

--Set @DisableIndex = (select 'Alter Index '+i.name+' on Relational.IronOfferMember Disable '  AS [text()]
--					 from sys.indexes as i
--					 inner join sys.objects as o
--							on o.object_id = i.object_id
--					 where i.is_disabled =0 and o.Name = 'IronOfferMember' and i.Type = 2
--					 For XML PATH ('')
--						)

--Exec sp_ExecuteSQL @DisableIndex

SELECT @msg = 'Drop ColumnStore Index - End'
EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

--------------------------------------------------------------------------------------------
------------------------------------Loop around adding memberships--------------------------
--------------------------------------------------------------------------------------------

Declare @RowNo int = 1,
		@RowNoMax int = (Select Max(RowNo) From #Offers),
		@OfferID int,
		@RowCount int = 0

While @RowNo <= @RowNoMax
Begin
	
	Set @OfferID = (Select IronOfferID From #Offers Where RowNo = @RowNo)
	
	SELECT @msg = 'Insert IronOffer '+Cast(@OfferID as varchar(12))+' - Start'
	EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

	---------------------------------------------------------------------------------------------
	---------------Insert all memberships with entries created on the date requested-------------
	---------------------------------------------------------------------------------------------
	Insert into Warehouse.Relational.IronOfferMember

	Select ioms.IronOfferID
		 , ioms.CompositeID
		 , ioms.StartDate
		 , ioms.EndDate
		 , ioms.ImportDate
	From SLC_Report.dbo.IronOfferMember ioms
	Inner join #Customers cu
		on ioms.CompositeID = cu.CompositeID
	where ioms.IronOfferID = @OfferID
	And ioms.ImportDate >= @SDate
	And ioms.ImportDate <  @EDate
	And Not Exists (Select 1
					From Warehouse.Relational.IronOfferMember iomw
					Where ioms.IronOfferID = iomw.IronOfferID
					And ioms.CompositeID = iomw.CompositeID
					And ioms.StartDate = iomw.StartDate)
	Set @RowCount = @RowCount + @@ROWCOUNT
	
	Set @RowNo = @RowNo+1

	SELECT @msg = 'Insert IronOffer '+Cast(@OfferID as varchar(12))+' - End'
	EXEC Staging.oo_TimerMessage @msg, @time OUTPUT
End


-------------------------------------------------------------------------------------------------
------------------------ Recreate previously dropped Index (ColumnStore) ------------------------
-------------------------------------------------------------------------------------------------
SELECT @msg = 'Recreate ColumnStore Index - Start'
EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

CREATE NONCLUSTERED COLUMNSTORE INDEX [CSX_IronOfferMember_All] ON [Relational].[IronOfferMember] ([IronOfferID], [CompositeID], [StartDate], [EndDate], [ImportDate])

--Set @DisableIndex = Replace(@DisableIndex,'disable','rebuild')

--Exec SP_ExecuteSQL @DisableIndex

SELECT @msg = 'Recreate ColumnStore Index - End'
EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

------------------------------------------------------------------------------------------------------------------------
------------------------------------Update entry in JobLog_Temp Table with End Date-------------------------------------
------------------------------------------------------------------------------------------------------------------------
UPDATE staging.JobLog_Temp
SET		EndDate = GETDATE(),
		TableRowCount = @RowCount
WHERE	StoredProcedureName = 'WarehouseLoad_IronOfferMembers_DailyBulkLoad' 
	AND TableSchemaName = 'Relational'
	AND TableName = 'IronofferMember' 
	AND EndDate IS NULL

------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------Insert entry into JobLog----------------------------------------------
------------------------------------------------------------------------------------------------------------------------
Insert into staging.JobLog
select [StoredProcedureName],
	[TableSchemaName],
	[TableName],
	[StartDate],
	[EndDate],
	[TableRowCount],
	[AppendReload]
from staging.JobLog_Temp

truncate table staging.JobLog_Temp

