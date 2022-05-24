-- =============================================
-- Author:		JEA
-- Create date: 05/03/2013
-- Description:	Fetches list of unbranded MIDs
-- in spend order for possible branding
-- =============================================
CREATE PROCEDURE gas.UnbrandedMIDAmounts_Fetch 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT b.BrandMIDID, c.Narrative, b.amount
	FROM
	(
		SELECT b.brandmidid, SUM(amount) AS amount
		FROM Relational.CardTransaction ct WITH (NOLOCK)
		INNER JOIN Relational.BrandMID b WITH (NOLOCK) on ct.BrandMIDID = b.BrandMIDID
		WHERE b.Country = 'GB'
		AND b.BrandID = 944
		AND ct.TranDate between DATEADD(month, -3, GETDATE()) and GETDATE()
		GROUP BY b.BrandMIDID
	) b
	INNER JOIN staging.Combination c on b.BrandMIDID = c.BrandMIDID
	ORDER BY b.amount DESC, b.BrandMIDID, c.Narrative
    
END
