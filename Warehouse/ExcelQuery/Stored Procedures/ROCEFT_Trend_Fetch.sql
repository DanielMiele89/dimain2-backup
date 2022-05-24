-- =============================================
-- Author:		<Shaun H>
-- Create date: <25/01/2019>
-- Description:	<Tool Export - Trend>
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_Trend_Fetch]
	(@BrandID INT)
AS
BEGIN
	SET NOCOUNT ON;

	SELECT		*
	FROM		Warehouse.ExcelQuery.ROCEFT_Trend
	WHERE		BrandID = @BrandID
	ORDER BY	ID

END
