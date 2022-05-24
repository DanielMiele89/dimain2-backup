-- =============================================
-- Author:		JEA
-- Create date: 17/07/2017
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_BrandList_ETLInsightStore_Fetch]
	
AS
BEGIN

	SET NOCOUNT ON;

	SELECT BrandID
		, BrandName
		, Core
		, Margin
		, [Override]
		, IsPartner
	FROM ExcelQuery.ROCEFT_BrandList

END