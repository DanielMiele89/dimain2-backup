-- =============================================
-- Author:		<Shaun H>
-- Create date: <19/06/2017>
-- Description:	<Tool Export - Spend Stretch>
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_SpendStretch_Fetch]
		(@BrandID int)
AS
BEGIN
	SET NOCOUNT ON;

	SELECT		ID
				,BrandID
				,Cumu_Percentage
				,Boundary
	FROM		Warehouse.ExcelQuery.ROCEFT_SpendStretch
	WHERE		BrandID = @BrandID
	ORDER BY	Cumu_Percentage DESC
END