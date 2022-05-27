
/*
Author:		Stuart Barnley
Date:		25th September 2015
Purpose:	Used to build a table of customers who have reach £5 cashback for the first time

Notes:		
*/
Create Procedure [Staging].[WarehouseLoad_Customer_Reach_5GBP]
as
/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'WarehouseLoad_Customer_Reach_5GBP',
		TableSchemaName = 'Relational',
		TableName = 'Customers_Reach5GBP',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'A'

Declare @RowNumber Int
Set @RowNumber = (Select Count(*) from Relational.Customers_Reach5GBP)

/*--------------------------------------------------------------------------------------------------
-----------------------------One off data Load to get up to date with those past the point----------
----------------------------------------------------------------------------------------------------*/
--Select Distinct FanID
--into Relational.Customers_Reach5GBP
--From relational.CustomerJourneyV2 as cj
--Where CustomerJourneyStatus in ('Mot3','Saver','Redeemer')
/*--------------------------------------------------------------------------------------------------
-----------------------------One off data Load to get up to date with those past the point----------
----------------------------------------------------------------------------------------------------*/
--Insert into Warehouse.Relational.Customers_Reach5GBP
--select Distinct ccb.FanID 
--from Staging.Customer_CashbackBalances as ccb
--left outer join Warehouse.Relational.Customers_Reach5GBP as g
--	on ccb.fanid = g.FanID
--Where ClubCashAvailable >= 5 and g.FanID is null

/*--------------------------------------------------------------------------------------------------
-----------------------------Add custoemrs who have reach £5 for the first time---------------------
----------------------------------------------------------------------------------------------------*/
Insert into Relational.Customers_Reach5GBP
select Distinct ccb.FanID 
from Staging.Customer_CashbackBalances as ccb
left outer join Relational.Customers_Reach5GBP as g
	on ccb.fanid = g.FanID
Where	ClubCashAvailable >= 5 and 
		g.FanID is null and
		ccb.Date = Dateadd(day,DATEDIFF(dd, 0, GETDATE()),0) 

/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'WarehouseLoad_Customer_Reach_5GBP' and
		TableSchemaName = 'Relational' and
		TableName = 'Customers_Reach5GBP' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  staging.JobLog_Temp
Set		TableRowCount = (Select COUNT(*) from Relational.Customers_Reach5GBP)-@RowNumber
where	StoredProcedureName = 'WarehouseLoad_Customer_Reach_5GBP' and
		TableSchemaName = 'Relational' and
		TableName = 'Customers_Reach5GBP' and
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