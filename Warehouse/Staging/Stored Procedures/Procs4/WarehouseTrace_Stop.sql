-- =============================================
-- Author:		JEA
-- Create date: 11/03/2013
-- Description:	Stops a query trace
-- =============================================
CREATE PROCEDURE Staging.WarehouseTrace_Stop 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    declare @Year Int, @Month Int, @Day Int, @StrDate nvarchar(256)

	SET @Year = YEAR(GETDATE())
	SET @Month = MONTH(GETDATE())
	SET @Day = DAY(GETDATE())

	SELECT @StrDate = N'C:\TraceImport\WarehouseTrace_' + CAST(@year as varchar(4)) + '_' + CAST(@month as varchar(2)) + '_' + CAST(@Day as varchar(2)) + '.trc'

	DECLARE @TraceID int
	SELECT  @TraceID = TraceID FROM ::fn_trace_getinfo(default) WHERE VALUE = @StrDate

	EXEC sp_trace_setstatus @TraceID, 0

	EXEC sp_trace_setstatus @TraceID, 2
END