/*
Author:		Stuart Barnley	
Date:		07th February 2014
Purpose:	Full load of LionSendComponent table, seperated from IronOfferMember due to the size of the 
			IOM table
			
		
Update:		SB 2017-03-22 - it appears the ImportDate field has been removed, this was not expected.
*/
CREATE Procedure [Staging].[WarehouseLoad_LionSendComponent_V1_3]
As

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @Now DATETIME, @OuterNow DATETIME, @RowCount INT, @Message VARCHAR(120)
DECLARE @NewLionSendID INT, @OldLionSendID INT;

Set @Now = GetDate()

--------------------------------------------------------------------------------------------------
-- Write entry to JobLog Table
--------------------------------------------------------------------------------------------------
Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'WarehouseLoad_LionSendComponent_V1_3',
		TableSchemaName = 'Relational',
		TableName = 'LionSendComponent',
		StartDate = @Now,
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'A'


--------------------------------------------------------------------------------------------------
-- Collect most recent lionSendID from SLC_Report and Warehouse
--------------------------------------------------------------------------------------------------

SELECT @NewLionSendID = MAX(LionSendID)
FROM SLC_Report.lion.LionSendComponent lsc
INNER JOIN relational.customer c
	ON lsc.CompositeID = c.CompositeID

SELECT @OldLionSendID = MAX(LionSendID)
FROM Relational.LionSendComponent lsc
INNER JOIN relational.customer c
	ON lsc.CompositeID = c.CompositeID

--------------------------------------------------------------------------------------------------
-- If there's a new LionSendID in SLC_Report then load it to Warehouse
--------------------------------------------------------------------------------------------------														
IF @OldLionSendID < @NewLionSendID 
BEGIN 
	SET @Now = GETDATE()

	INSERT INTO Relational.LionSendComponent 
		(CompositeID, FanID, TypeID, IronOfferID, OfferSlot, LionSendID)
	SELECT  
		lsc.CompositeID,
		c.FanID,
		TypeID,
		CAST(lsc.ItemID as int) as IronOfferID,
		CAST(lsc.ItemRank as int) as OfferSlot,
		lsc.LionSendID
	FROM SLC_Report.lion.LionSendComponent lsc with (nolock)
	INNER JOIN Relational.Customer c with (nolock)
		ON lsc.CompositeID = c.CompositeID
	WHERE lsc.LionSendID = @NewLionSendID
	SET @RowCount = @@ROWCOUNT

END 


--------------------------------------------------------------------------------------------------
-- Update entry in JobLog Table with End Date, Row Count
--------------------------------------------------------------------------------------------------
SET @Now = GETDATE()

UPDATE staging.JobLog_Temp SET		
	EndDate = @Now,
	TableRowCount = @RowCount
WHERE StoredProcedureName = 'WarehouseLoad_LionSendComponent_V1_3' 
	AND TableSchemaName = 'Relational' 
	AND TableName = 'LionSendComponent' 

INSERT INTO staging.JobLog
SELECT [StoredProcedureName],
	[TableSchemaName],
	[TableName],
	[StartDate],
	[EndDate],
	[TableRowCount],
	[AppendReload]
FROM staging.JobLog_Temp

TRUNCATE TABLE staging.JobLog_Temp

