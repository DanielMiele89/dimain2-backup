-- =============================================
-- Author:		JEA
-- Create date: 19/03/2013
-- Description:	List of unbranded brandmids 
-- with the highest spend against them
-- =============================================
CREATE PROCEDURE Staging.UnmatchedBrandMIDs_Fetch
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT TOP 50000 bm.brandmidid,bm.narrative, SUM(ct.amount) as amount
	FROM Relational.BrandMID bm
	INNER JOIN Relational.CardTransaction ct on bm.BrandMIDID = ct.BrandMIDID
	WHERE ct.TranDate between DATEADD(month, -6, getdate()) and GETDATE()
	AND BM.BrandID = 944
	AND BM.BrandMIDID != 147179 --foreign transactions
	AND BM.BrandMIDID != 142652 --paypal
	GROUP BY BM.BrandMIDID, BM.Narrative
	ORDER BY amount DESC
	
	SELECT * FROM Relational.BrandMID WHERE BrandID = 943
	
END