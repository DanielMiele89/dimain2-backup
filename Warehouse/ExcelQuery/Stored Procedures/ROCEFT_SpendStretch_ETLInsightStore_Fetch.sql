-- =============================================
-- Author:		JEA
-- Create date: 19/06/2017
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE ExcelQuery.ROCEFT_SpendStretch_ETLInsightStore_Fetch 
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT ID
		, BrandID
		, Cumu_Percentage
		, Boundary
	FROM ExcelQuery.ROCEFT_SpendStretch

END
