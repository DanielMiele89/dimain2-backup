-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE ExcelQuery.MVP_SpendStretchPropensityRank_Fetch 
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT PKID, RunDate, GroupName, BrandID, ID
		, PropensityRank, CumulativePercentage, Boundary
	FROM ExcelQuery.MVP_SpendStretchPropensityRank

END
