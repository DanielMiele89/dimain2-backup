-- =============================================
-- Author:		JEA
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE Prototype.OPECustomerPropensity_Ratio_Fetch
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT s.BrandID, s.CINID, s.Propensity/b.Ratio AS Propensity
	FROM Prototype.OPECustomerPropensity_Stage s
	INNER JOIN Prototype.OPEBrandRatio b ON s.BrandID = b.BrandID AND s.PropClass = b.PropClass

END
