-- =============================================
-- Author:		<Shaun H>
-- Create date: <11/07/2017>
-- Description:	<Tool Export - Brands>
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_Brands_Fetch]
AS
BEGIN
	SET NOCOUNT ON;

	SELECT		*
	FROM		Warehouse.ExcelQuery.ROCEFT_BrandList
	ORDER BY	BrandName
END
