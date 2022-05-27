-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE AWSFile.ComboPostCode_Refresh
	
AS
BEGIN
	
	SET NOCOUNT ON;

    INSERT INTO AWSFile.Location(BrandID, PostCode)
	SELECT BrandID, PostCode
	FROM AWSFile.PostCode_NewPostCodeMatch
	EXCEPT
	SELECT BrandID, PostCode
	FROM AWSFile.Location

	UPDATE c
	SET PostCode = l.PostCode, LocationID = l.LocationID
	FROM AWSFile.ComboPostCode c
	INNER JOIN AWSFile.PostCode_NewPostCodeMatch n ON c.ConsumerCombinationID = n.ConsumerCombinationID
	INNER JOIN AWSFile.Location l ON n.BrandID = l.BrandID and n.PostCode = l.PostCode

	INSERT INTO AWSFile.ComboPostCode(ConsumerCombinationID, PostCode, LocationID)
	SELECT n.ConsumerCombinationID, n.PostCode, l.LocationID
	FROM AWSFile.PostCode_NewPostCodeMatch n
	INNER JOIN AWSFile.Location l ON n.BrandID = l.BrandID and n.PostCode = l.PostCode
	LEFT OUTER JOIN  AWSFile.ComboPostCode c ON n.ConsumerCombinationID = c.ConsumerCombinationID
	WHERE c.ConsumerCombinationID IS NULL

END
