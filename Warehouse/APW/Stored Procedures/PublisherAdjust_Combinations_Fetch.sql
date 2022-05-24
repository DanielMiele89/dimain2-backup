-- =============================================
-- Author:		JEA
-- Create date: 07/10/2016
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE APW.PublisherAdjust_Combinations_Fetch 
	
AS
BEGIN

	SET NOCOUNT ON;

	SELECT c.ConsumerCombinationID, r.BrandID
	FROM Relational.ConsumerCombination c
	INNER JOIN APW.PublisherAdjust_Brand r ON c.BrandID = r.BrandID
	ORDER BY r.BrandID

END
