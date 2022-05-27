-- =============================================
-- Author:		JEA
-- Create date: 13/12/2012
-- Description:	Returns the value of a SQL Performance counter
-- =============================================
CREATE FUNCTION [Staging].[GetSQLPerfCounterValue]
(
	@ObjName varchar(50)
	, @CtrName varchar(50)
	, @InstanceName varchar(50)
)
RETURNS bigint
AS
BEGIN
	-- Declare the return variable here
	DECLARE @CtrResult bigint

	-- Add the T-SQL statements to compute the return value here
	SELECT @CtrResult = cntr_value
	FROM sys.dm_os_performance_counters
	WHERE object_name = @ObjName
	AND counter_name = @CtrName
	AND instance_name = @InstanceName

	-- Return the result of the function
	RETURN @CtrResult

END
