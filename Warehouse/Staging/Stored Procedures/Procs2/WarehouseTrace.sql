-- =============================================
-- Author:		JEA
-- Create date: 11/03/2013
-- Description:	Starts a query trace
-- =============================================
CREATE PROCEDURE [Staging].WarehouseTrace
	
AS
BEGIN
	
	SET NOCOUNT ON;

    DECLARE 
		@TraceFileName NVARCHAR(245), 
		@EndDate DATETIME,
		@MaxFileSize BIGINT = 50

	SET @EndDate = CONVERT(DATETIME, CONVERT(VARCHAR(10),GETDATE(),120) + ' 18:00:00.000')

	SELECT @TraceFileName = N'C:\TraceImport\WarehouseTrace_' + REPLACE(CONVERT(VARCHAR(10),GETDATE(),102),'.','_')

	DECLARE @RC INT, @TraceID INT, @on BIT
	EXEC @rc = sp_trace_create @TraceID OUTPUT, 0, @TraceFileName, @MaxFileSize, @EndDate

	SELECT @on = 1

	EXEC sp_trace_setevent @TraceID, 10, 1, @on
	EXEC sp_trace_setevent @TraceID, 10, 10, @on
	EXEC sp_trace_setevent @TraceID, 10, 6, @on
	EXEC sp_trace_setevent @TraceID, 10, 11, @on
	EXEC sp_trace_setevent @TraceID, 10, 18, @on
	EXEC sp_trace_setevent @TraceID, 10, 16, @on
	EXEC sp_trace_setevent @TraceID, 10, 17, @on
	EXEC sp_trace_setevent @TraceID, 10, 13, @on
	EXEC sp_trace_setevent @TraceID, 10, 9, @on
	EXEC sp_trace_setevent @TraceID, 10, 12, @on
	EXEC sp_trace_setevent @TraceID, 10, 14, @on
	EXEC sp_trace_setevent @TraceID, 10, 15, @on
	EXEC sp_trace_setevent @TraceID, 10, 2, @on

	EXEC sp_trace_setevent @TraceID, 12, 1, @on
	EXEC sp_trace_setevent @TraceID, 12, 10, @on
	EXEC sp_trace_setevent @TraceID, 12, 6, @on
	EXEC sp_trace_setevent @TraceID, 12, 11, @on
	EXEC sp_trace_setevent @TraceID, 12, 18, @on
	EXEC sp_trace_setevent @TraceID, 12, 16, @on
	EXEC sp_trace_setevent @TraceID, 12, 17, @on
	EXEC sp_trace_setevent @TraceID, 12, 13, @on
	EXEC sp_trace_setevent @TraceID, 12, 9, @on
	EXEC sp_trace_setevent @TraceID, 12, 12, @on
	EXEC sp_trace_setevent @TraceID, 12, 14, @on
	EXEC sp_trace_setevent @TraceID, 12, 15, @on
	EXEC sp_trace_setevent @TraceID, 12, 2, @on

	EXEC sp_trace_setfilter @TraceID, 6, 0, 7, N'SYSTEM%'
	EXEC sp_trace_setfilter @TraceID, 3, 0, 0, 17

	EXEC @RC = sp_trace_setstatus @TraceID, 1
END
