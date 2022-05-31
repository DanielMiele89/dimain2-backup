
-- *******************************************************************************
-- Author: Stuart Barnley
-- Create date: 01/08/2016
-- Description: update warehouse.iron.PrimaryRetailerIdentification table with new partner ids
-- *******************************************************************************
CREATE PROCEDURE [Staging].[WarehouseLoad_PrimaryRetailerIdentification]
		
AS
BEGIN
	SET NOCOUNT ON;

/******************************************************************************
***********************Write entry to JobLog Table*****************************
******************************************************************************/
INSERT INTO Staging.JobLog_Temp
SELECT	StoredProcedureName = 'WarehouseLoad_PrimaryRetailerIdentification',
	TableSchemaName = 'Iron',
	TableName = 'PrimaryRetailerIdentification',
	StartDate = GETDATE(),
	EndDate = NULL,
	TableRowCount  = NULL,
	AppendReload = 'A'


Insert into Warehouse.Iron.PrimaryRetailerIdentification
select p.PartnerID,Null
from Relational.partner as p
Left Outer join Warehouse.Iron.PrimaryRetailerIdentification as a
	on p.partnerid = a.PartnerID
Where a.PartnerID is null

/******************************************************************************
****************Update entry in JobLog Table with End Date*********************
******************************************************************************/
UPDATE Staging.JobLog_Temp
SET EndDate = GETDATE()
WHERE	StoredProcedureName = 'WarehouseLoad_PrimaryRetailerIdentification' 
	AND TableSchemaName = 'Iron'
	AND TableName = 'PrimaryRetailerIdentification' 
	AND EndDate IS NULL

INSERT INTO Staging.JobLog
SELECT	StoredProcedureName,
	TableSchemaName,
	TableName,
	StartDate,
	EndDate,
	TableRowCount,
	AppendReload
FROM Staging.JobLog_Temp

TRUNCATE TABLE Staging.JobLog_Temp

END
