-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE ExcelQuery.MVP_BrandList_Fetch 
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT ID, BrandID, BrandName, AcquireLength, LapsedLength
		, [Override], IsPartner, StartDate, EndDate
	FROM ExcelQuery.MVP_BrandList

END