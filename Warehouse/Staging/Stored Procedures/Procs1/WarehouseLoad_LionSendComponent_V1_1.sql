/*
Author:		Stuart Barnley	
Date:		07th February 2014
Purpose:	Full load of LionSendComponent table, seperated from IronOfferMember due to the size of the 
			IOM table
			
		
Update:		
*/
CREATE Procedure [Staging].[WarehouseLoad_LionSendComponent_V1_1]
As
/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'WarehouseLoad_LionSendComponent_V1_1',
		TableSchemaName = 'Relational',
		TableName = 'LionSendComponent',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'A'
---------------------------------------------------------------------------------
----------------------------------Get a row Count--------------------------------
---------------------------------------------------------------------------------
Declare @RowCount bigint
Set @RowCount = (Select Count(1) from Relational.LionSendComponent with (nolock))

---------------------------------------------------------------------------------
-------------Copy slc_report.lion.LionSendComponent into Staging table ----------
---------------------------------------------------------------------------------


--Truncate Table Relational.LionSendComponent
declare @StartRow BigInt,@ChunkSize int, @SLCSize int
Set		@StartRow = (SELECT MAX(CAST(ID as Int)) from Relational.LionSendComponent) --Last row in existing Table
Set		@ChunkSize = 250000	-- size of data chunk to loaded
Set		@SLCSize = (Select Max(ID)--****************************************************************************************
					from SLC_Report.lion.LionSendComponent as lsc--****************Last Customer record*********************
					inner join relational.customer as c--***************************in LSC table****************************
						on lsc.CompositeID = c.CompositeID)--***************************************************************
								
If @StartRow < @SLCSize 
Begin
While @StartRow < @SLCSize
Begin
Insert Into Relational.LionSendComponent
	Select   Top (@ChunkSize) 
			 CAST(lsc.ID as Int) as ID
			,CAST(lsc.CompositeID as bigint)	as CompositeID
			,CAST(c.FanID as int)			as FanID
			,CAST(lsc.TypeID as int)		as TypeID
			,CAST(lsc.ItemID as int)		as IronOfferID
			,CAST(lsc.ItemRank as int)		as OfferSlot
			,CAST(lsc.LionSendID as int)		as LionSendID
			,CAST(lsc.ImportDate as datetime)	as ImportDate
	From SLC_Report.lion.LionSendComponent as lsc with (nolock)
	inner join Relational.Customer c with (nolock)
			on lsc.CompositeID = c.CompositeID
	Where	lsc.ID > @StartRow
	Order by ID
Set @StartRow = (Select MAX(ID) from Relational.LionSendComponent with (nolock))
End


---------------------------------------------------------------------------------
------------------------Add Indexes and Primary Key------------------------------
---------------------------------------------------------------------------------
ALTER INDEX ALL ON Relational.LionSendComponent REBUILD
End

------------------------------------------------------------------------------------------------------
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'WarehouseLoad_LionSendComponent_V1_1' and
		TableSchemaName = 'Relational' and
		TableName = 'LionSendComponent' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  staging.JobLog_Temp
Set		TableRowCount = (Select COUNT(1) from Relational.LionSendComponent) - @RowCount
where	StoredProcedureName = 'WarehouseLoad_LionSendComponent_V1_1' and
		TableSchemaName = 'Relational' and
		TableName = 'LionSendComponent' and
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