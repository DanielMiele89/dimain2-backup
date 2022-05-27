-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE AWSFile.AlternateLocation_Fetch 

AS
BEGIN

	SET NOCOUNT ON;

    SELECT ID
		, BrandID
		, PostCode
		, LocationFormat
		, LocationCategory
	FROM AWSFile.AlternateLocation

END
