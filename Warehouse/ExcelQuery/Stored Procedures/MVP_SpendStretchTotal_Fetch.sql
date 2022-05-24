-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE ExcelQuery.MVP_SpendStretchTotal_Fetch 
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT PKID, RunDate, GroupName, BrandID, ID
		, CumulativePercentage, Boundary
	FROM ExcelQuery.MVP_SpendStretchTotal

END