-- =============================================
-- Author:		<Phil L>
-- Create date: <02/07/2015>
-- Description:	<Get list of included partners and date for generating next output>
-- =============================================
CREATE PROCEDURE excelquery.AllPartner_WMTR_Results
	-- Add the parameters for the stored procedure here
(@pname	VARCHAR(255) = NULL)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

SELECT  partnername
		,brandname
		,CY_Sales_share
		,PY_sales_share
		,CY_Sales_share-PY_sales_share as ABS_Marketshare_Growth
		,CY_sales
		,CONVERT(decimal(5,4),(CONVERT(float,CY_sales )/ PY_Sales)) - 1 as CY_Sales_Growth

FROM Warehouse.ExcelQuery.WMTR_output
WHERE partnername = @pname OR @pname IS NULL



END