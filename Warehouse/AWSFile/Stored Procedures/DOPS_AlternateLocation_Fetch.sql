-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [AWSFile].[DOPS_AlternateLocation_Fetch] 
WITH EXECUTE AS OWNER

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