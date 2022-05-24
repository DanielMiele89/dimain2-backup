
-- *******************************************************************************
-- Author: Suraj Chahal
-- Create date: 14/05/2015
-- Description: Updates the CurrentlyActive field on the Partner Table. 
-- *******************************************************************************
CREATE PROCEDURE [Staging].[WarehouseLoad_Partner_CurrentlyActive]
		
AS
BEGIN
	SET NOCOUNT ON;

/******************************************************************************
***********************Write entry to JobLog Table*****************************
******************************************************************************/
INSERT INTO staging.JobLog_Temp
SELECT	StoredProcedureName = 'WarehouseLoad_Partner_CurrentlyActive',
	TableSchemaName = 'Relational',
	TableName = 'Partner',
	StartDate = GETDATE(),
	EndDate = null,
	TableRowCount  = null,
	AppendReload = 'A'


/************************************************************************************************
***************************************Query Start***********************************************
************************************************************************************************/
UPDATE Warehouse.Relational.Partner
SET CurrentlyActive = (CASE WHEN pl.PartnerID IS NOT NULL THEN 1 ELSE 0 END)
FROM Warehouse.Relational.Partner p
LEFT OUTER JOIN	(
		SELECT	DISTINCT
			p.PartnerID
		FROM Warehouse.Relational.Partner p
		INNER JOIN Warehouse.Relational.IronOffer io
			ON p.PartnerID = io.PartnerID
		INNER JOIN Warehouse.Relational.IronOfferMember iom
			ON io.IronOfferID = iom.IronOfferID
		WHERE	IsSignedOff = 1
			AND (io.EndDate IS NULL OR io.EndDate >= GETDATE())
			AND io.IsTriggerOffer = 0
		)pl
	ON p.PartnerID = pl.PartnerID


/************************************************************************************************
*****************************************Query End***********************************************
************************************************************************************************/

/******************************************************************************
****************Update entry in JobLog Table with End Date*********************
******************************************************************************/
UPDATE staging.JobLog_Temp
SET EndDate = GETDATE()
WHERE	StoredProcedureName = 'WarehouseLoad_Partner_CurrentlyActive' 
	AND TableSchemaName = 'Relational'
	AND TableName = 'Partner' 
	AND EndDate IS NULL

/******************************************************************************
*****************Update entry in JobLog Table with Row Count*******************
******************************************************************************/
--**Count run seperately as when table grows this as a task on its own may 
--**take several minutes and we do not want it included in table creation times
UPDATE Staging.JobLog_Temp
SET TableRowCount = (SELECT COUNT(1) FROM Warehouse.Relational.Partner)
WHERE	StoredProcedureName = 'WarehouseLoad_Partner_CurrentlyActive'
	AND TableSchemaName = 'Relational'
	AND TableName = 'Partner' 
	AND TableRowCount IS NULL


INSERT INTO Staging.JobLog
SELECT	StoredProcedureName,
	TableSchemaName,
	TableName,
	StartDate,
	EndDate,
	TableRowCount,
	AppendReload
FROM Staging.JobLog_Temp

TRUNCATE TABLE staging.JobLog_Temp


END