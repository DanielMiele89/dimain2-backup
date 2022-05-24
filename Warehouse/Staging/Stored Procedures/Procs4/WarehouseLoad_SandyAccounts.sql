
/*
	Author:			Stuart Barnley
	Date:			31-03-2014
	Description:	This Stored procedure is made to update daily the Sandy group to populate the CinIDs
*/
CREATE Procedure [Staging].[WarehouseLoad_SandyAccounts]
as
------------------------------------------------------------------------------------------------------------
--------------------------------------Create Original Data Table--------------------------------------------
------------------------------------------------------------------------------------------------------------
--This should only be run once to get list of customers
/*
Select Distinct 
		FanID,
		[Group],
		1 as Batch
Into Staging.SandyAccounts
from SLC_Report..CBP_SandyAccounts
*/

/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'WarehouseLoad_SandyAccounts',
		TableSchemaName = 'Relational',
		TableName = 'SandyAccount_IncCINIDs',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'R'


------------------------------------------------------------------------------------------------------------
--------------------------------Create Table of Sandy People and their CINIDs-------------------------------
------------------------------------------------------------------------------------------------------------

--Create Table Relational.SandyAccount_IncCINIDs (FanID int,[Group] varchar(3),Batch int, SourceUID varchar(10), CinID int)

--Over time we may gain CINIDs
Truncate table Relational.SandyAccount_IncCINIDs
Insert into Relational.SandyAccount_IncCINIDs
Select	d.*,
		f.SourceUID,
		cl.CINID
from Staging.SandyAccounts as d
inner join slc_report.dbo.fan as f
	on d.FanID = f.ID
Left Outer join Warehouse.relational.cinlist as cl
	on f.SourceUID = cl.CIN
Order by CinID
----138941


/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'WarehouseLoad_SandyAccounts' and
		TableSchemaName = 'Relational' and
		TableName = 'SandyAccount_IncCINIDs' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  staging.JobLog_Temp
Set		TableRowCount = ((Select COUNT(1) from Warehouse.Relational.SandyAccount_IncCINIDs))
where	StoredProcedureName = 'WarehouseLoad_SandyAccounts' and
		TableSchemaName = 'Relational' and
		TableName = 'SandyAccount_IncCINIDs' and
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