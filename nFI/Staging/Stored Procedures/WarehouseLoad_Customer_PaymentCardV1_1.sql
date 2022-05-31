
-- ************************************************************************************
-- Author: Suraj Chahal
-- Create date: 05/02/2016
-- Description: Relational.Customer_PaymentCard with new entries and end date old ones
-- ************************************************************************************
CREATE PROCEDURE [Staging].[WarehouseLoad_Customer_PaymentCardV1_1]
		
AS
BEGIN
	SET NOCOUNT ON;

/******************************************************************************
***********************Write entry to JobLog Table*****************************
******************************************************************************/
INSERT INTO Staging.JobLog_Temp
SELECT	StoredProcedureName = 'WarehouseLoad_Customer_PaymentCardV1_1',
	TableSchemaName = 'Relational',
	TableName = 'Customer_PaymentCard',
	StartDate = GETDATE(),
	EndDate = NULL,
	TableRowCount  = NULL,
	AppendReload = 'R'

Truncate Table Relational.Customer_PaymentCard

ALTER INDEX IDX_FanID ON nFI.Relational.Customer_PaymentCard DISABLE
ALTER INDEX IDX_PanID ON nFI.Relational.Customer_PaymentCard DISABLE

Insert INTO Relational.Customer_PaymentCard
SELECT	PanID,
	cb.FanID,
	ClubID,
	pc.PaymentCardID,
	pc.PaymentCardTypeID,
	pc.AdditionDate as StartDate,
	Case
		When RemovalDate is null then DuplicationDate
		When DuplicationDate is null then RemovalDate
		When DuplicationDate < RemovalDate then DuplicationDate
		Else RemovalDate
	End as EndDate
FROM Relational.Customer cb
INNER JOIN
	(
	SELECT	p.ID as PanID,
		CompositeID,
		p.PaymentCardID,
		p.AdditionDate,
		p.DuplicationDate,
		p.RemovalDate,
		pc.CardTypeID as PaymentCardTypeID
	FROM SLC_Report.dbo.Pan p
	INNER JOIN SLC_Report.dbo.PaymentCard pc
		ON p.PaymentCardID = pc.ID
	)pc
	ON cb.CompositeID = pc.CompositeID


ALTER INDEX IDX_FanID ON nFI.Relational.Customer_PaymentCard REBUILD
ALTER INDEX IDX_PanID ON nFI.Relational.Customer_PaymentCard REBUILD
	

/******************************************************************************
****************Update entry in JobLog Table with End Date*********************
******************************************************************************/
UPDATE Staging.JobLog_Temp
SET EndDate = GETDATE()
WHERE	StoredProcedureName = 'WarehouseLoad_Customer_PaymentCardV1_1' 
	AND TableSchemaName = 'Relational'
	AND TableName = 'Customer_PaymentCard' 
	AND EndDate IS NULL

/******************************************************************************
*****************Update entry in JobLog Table with Row Count*******************
******************************************************************************/
--**Count run seperately as when table grows this as a task on its own may 
--**take several minutes and we do not want it included in table creation times
UPDATE Staging.JobLog_Temp
SET TableRowCount = (SELECT COUNT(1) FROM Relational.Customer_PaymentCard)
WHERE	StoredProcedureName = 'WarehouseLoad_Customer_PaymentCardV1_1' 
	AND TableSchemaName = 'Relational'
	AND TableName = 'Customer_PaymentCard' 
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

TRUNCATE TABLE Staging.JobLog_Temp


END
