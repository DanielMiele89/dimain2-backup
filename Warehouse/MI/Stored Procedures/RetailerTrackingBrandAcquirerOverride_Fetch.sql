-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE MI.RetailerTrackingBrandAcquirerOverride_Fetch

AS
BEGIN

	SET NOCOUNT ON;

    SELECT b.BrandID, b.BrandName AS  Brand, a.AcquirerName AS Acquirer
	FROM MI.RetailerTrackingBrandAcquirerOverride o
	INNER JOIN Relational.Brand b ON o.BrandID = b.BrandID
	INNER JOIN Relational.Acquirer a ON o.AcquirerID = a.AcquirerID
	ORDER BY Brand

END