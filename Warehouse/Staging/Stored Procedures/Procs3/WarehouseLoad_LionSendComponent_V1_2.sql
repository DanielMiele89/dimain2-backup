/*
Author:		Stuart Barnley	
Date:		07th February 2014
Purpose:	Full load of LionSendComponent table, seperated from IronOfferMember due to the size of the 
			IOM table
			
		
Update:		
*/
CREATE Procedure [Staging].[WarehouseLoad_LionSendComponent_V1_2]
As

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @Now DATETIME, @OuterNow DATETIME, @RowCount INT, @Message VARCHAR(120)
DECLARE @NewLionSendID INT, @OldLionSendID INT;

--EXEC [dbo].[oo_TimerMessage] 'Started WarehouseLoad_LionSendComponent', @Now, @@ROWCOUNT  


--------------------------------------------------------------------------------------------------
-- Write entry to JobLog Table
--------------------------------------------------------------------------------------------------
Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'WarehouseLoad_LionSendComponent_V1_2',
		TableSchemaName = 'Relational',
		TableName = 'LionSendComponent',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'A'


--------------------------------------------------------------------------------------------------
-- Collect most recent lionSendID from SLC_Report and Warehouse
--------------------------------------------------------------------------------------------------
SET @Now = GETDATE()
SELECT @NewLionSendID = MAX(LionSendID)
FROM SLC_Report.lion.LionSendComponent lsc
INNER JOIN relational.customer c
	ON lsc.CompositeID = c.CompositeID
--EXEC [dbo].[oo_TimerMessage] 'Get max LionSendID from SLC_Report', @Now, @NewLionSendID  

SET @Now = GETDATE()
SELECT @OldLionSendID = MAX(LionSendID)
FROM Relational.LionSendComponent lsc
INNER JOIN relational.customer c
	ON lsc.CompositeID = c.CompositeID
--EXEC [dbo].[oo_TimerMessage] 'Get max LionSendID from Warehouse', @Now, @OldLionSendID  


--------------------------------------------------------------------------------------------------
-- If there's a new LionSendID in SLC_Report then load it to Warehouse
--------------------------------------------------------------------------------------------------														
IF @OldLionSendID < @NewLionSendID 
BEGIN 
	SET @Now = GETDATE()

	INSERT INTO Relational.LionSendComponent 
		(CompositeID, FanID, TypeID, IronOfferID, OfferSlot, LionSendID, ImportDate)
	SELECT  
		lsc.CompositeID,
		c.FanID,
		TypeID,
		CAST(lsc.ItemID as int) as IronOfferID,
		CAST(lsc.ItemRank as int) as OfferSlot,
		lsc.LionSendID,
		lsc.ImportDate
	FROM SLC_Report.lion.LionSendComponent lsc with (nolock)
	INNER JOIN Relational.Customer c with (nolock)
		ON lsc.CompositeID = c.CompositeID
	WHERE lsc.LionSendID = @NewLionSendID
	SET @RowCount = @@ROWCOUNT

--	SET @Message = 'Loading LionSendID ' + CAST(@NewLionSendID AS varchar(5)) + ' to Warehouse'
--	EXEC [dbo].[oo_TimerMessage] @Message, @Now, @RowCount  

--	SET @Now = GETDATE()
--	UPDATE STATISTICS Relational.LionSendComponent --WITH FULLSCAN
--	EXEC [dbo].[oo_TimerMessage] 'Updated statistics', @Now, @@ROWCOUNT  

END 


--------------------------------------------------------------------------------------------------
-- Update entry in JobLog Table with End Date, Row Count
--------------------------------------------------------------------------------------------------
--SET @Now = GETDATE()
UPDATE staging.JobLog_Temp SET		
	EndDate = GETDATE(),
	TableRowCount = @RowCount
WHERE StoredProcedureName = 'WarehouseLoad_LionSendComponent_V1_2' 
	AND TableSchemaName = 'Relational' 
	AND TableName = 'LionSendComponent' 
--EXEC [dbo].[oo_TimerMessage] 'Update entry in JobLog Table with Row Count', @Now, @@ROWCOUNT  

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

--EXEC [dbo].[oo_TimerMessage] 'Finished WarehouseLoad_LionSendComponent', @Now, @@ROWCOUNT  

--RETURN 0