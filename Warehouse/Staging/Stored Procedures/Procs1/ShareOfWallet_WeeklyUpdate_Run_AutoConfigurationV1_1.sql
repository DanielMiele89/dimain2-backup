/*
		
		Author:		Stuart Barnley

		Date:		11th January 2016

		Purpose:	Update the contents of PartnerStrings so that only the needed SoWs are run.

					This has been written to call the original Stored Procedure so that we do 
					not lose the functality of the original stored procedure.
		
		Update:		N/A

*/

Create Procedure	[Staging].[ShareOfWallet_WeeklyUpdate_Run_AutoConfigurationV1_1]

As

/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog_Temp Table---------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'ShareOfWallet_WeeklyUpdate_RunAutoConfigurationV1_1',
		TableSchemaName = 'Relational',
		TableName = 'PartnerStrings',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'U'

/*--------------------------------------------------------------------------------------------------
------------------------------Declare and Set Parameters--------------------------------------------
----------------------------------------------------------------------------------------------------*/


Declare @EDate Date,		-- Date at which offers need to have started (end)

		@Today Date,		-- used to store todays date		

		@Update bit			-- 0 = see what records would be set, 1 = change contents of 
							-- Warehouse.Relational.PartnerStrings

Set		@Today = Dateadd(day,DATEDIFF(dd, 0, GETDATE())-0,0)

Set		@EDate = Dateadd(Day,8,@Today)

Set		@Update = 1

/*--------------------------------------------------------------------------------------------------
------------------------------Excute the Stored Procedure-------------------------------------------
----------------------------------------------------------------------------------------------------*/

Exec	[Staging].[ShareOfWallet_WeeklyUpdate_AutoConfiguration] @Today, @EDate, @Update

/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog_Temp Table with End Date--------------------------
----------------------------------------------------------------------------------------------------*/

Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'ShareOfWallet_WeeklyUpdate_RunAutoConfigurationV1_1' and
		TableSchemaName = 'Relational' and
		TableName = 'PartnerStrings' and
		EndDate is null

/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog_Temp Table with Row Count-------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times

Update  staging.JobLog_Temp
Set		TableRowCount = (Select Count(*) from Relational.PartnerStrings)
where	StoredProcedureName = 'ShareOfWallet_WeeklyUpdate_RunAutoConfigurationV1_1' and
		TableSchemaName = 'Relational' and
		TableName = 'PartnerStrings' and
		TableRowCount is null

/*--------------------------------------------------------------------------------------------------
---------------------------------Insert entries in to Joblog table----------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into staging.JobLog

select	[StoredProcedureName],
		[TableSchemaName],
		[TableName],
		[StartDate],
		[EndDate],
		[TableRowCount],
		[AppendReload]
from staging.JobLog_Temp

/*--------------------------------------------------------------------------------------------------
------------------------------Remove all entries from Joblog_Temp table-----------------------------
----------------------------------------------------------------------------------------------------*/

truncate table staging.JobLog_Temp