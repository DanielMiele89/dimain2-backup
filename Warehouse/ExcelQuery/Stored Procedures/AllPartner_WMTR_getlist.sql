-- =============================================
-- Author:		<Phil L>
-- Create date: <02/07/2015>
-- Description:	<Get list of included partners and date for generating next output>
-- =============================================
CREATE PROCEDURE excelquery.AllPartner_WMTR_getlist
	-- Add the parameters for the stored procedure here
--	<@Param1, sysname, @p1> <Datatype_For_Param1, , int> = <Default_Value_For_Param1, , 0>, 
--	<@Param2, sysname, @p2> <Datatype_For_Param2, , int> = <Default_Value_For_Param2, , 0>
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT distinct partnername
		,reportdate
	FROM Warehouse.ExcelQuery.WMTR_output
	ORDER BY partnername


END
