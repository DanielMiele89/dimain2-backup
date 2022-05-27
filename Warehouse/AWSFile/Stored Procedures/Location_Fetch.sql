-- =============================================
-- Author:		JEA
-- Create date: 08/11/2017
-- Description:	Retrieves Location information for AWS File
-- =============================================
CREATE PROCEDURE [AWSFile].[Location_Fetch] 
	
AS
BEGIN

	SET NOCOUNT ON;

	SELECT LocationID
		, BrandID
		, PostCode
	FROM AWSFile.Location
    
END
