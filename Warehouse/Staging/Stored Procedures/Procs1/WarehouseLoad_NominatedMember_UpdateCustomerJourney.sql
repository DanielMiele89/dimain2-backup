/*
Author:		Suraj Chahal
Date:		02-08-2013
Purpose:	Update customer Journey status in NominatedMember Table on a daily basis

*/
CREATE PROCEDURE [Staging].[WarehouseLoad_NominatedMember_UpdateCustomerJourney]
AS
BEGIN

/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'WarehouseLoad_NominatedMember_UpdateCustomerJourney',
		TableSchemaName = 'Lion',
		TableName = 'NominatedMember',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'R'


----------------------------------------------
TRUNCATE TABLE  warehouse.lion.NominatedMember
----------------------------------------------

INSERT INTO warehouse.lion.NominatedMember
SELECT      c.CompositeID, ShortCode
FROM Relational.CustomerJourney cj
INNER JOIN relational.customer c
      ON cj.FanID = c.FanID
WHERE cj.EndDate IS NULL


/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'WarehouseLoad_NominatedMember_UpdateCustomerJourney' and
		TableSchemaName = 'Lion' and
		TableName = 'NominatedMember' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  staging.JobLog_Temp
Set		TableRowCount = ((Select COUNT(*) from Lion.NominatedMember))
where	StoredProcedureName = 'WarehouseLoad_NominatedMember_UpdateCustomerJourney' and
		TableSchemaName = 'Lion' and
		TableName = 'NominatedMember' and
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



END

