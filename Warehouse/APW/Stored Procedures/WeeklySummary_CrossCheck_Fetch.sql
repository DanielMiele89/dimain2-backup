-- =============================================
-- Author:		JEA
-- Create date: 25/08/2016
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE APW.WeeklySummary_CrossCheck_Fetch
(
	@EndDate DATE
)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @StartDate DATE
	SET @StartDate = DATEADD(DAY, -6, @EndDate)
	
	SELECT PartnerID AS RetailerID
		, SUM(MyRewardsSpend) As MyRewardsSpend
		, SUM(nfispend) as nFISpend
	FROM
	(
		SELECT P.PartnerID, SUM(transactionamount) AS MyRewardsSpend, 0 AS nFISpend
		FROM Relational.[Partner] p
		INNER JOIN Relational.PartnerTrans pt WITH (NOLOCK) ON p.PartnerID = pt.PartnerID
		WHERE pt.TransactionDate BETWEEN @StartDate AND @EndDate
		GROUP BY p.PartnerID
	
		UNION ALL
	
		SELECT P.PartnerID, 0 AS MyRewardsSpend, SUM(transactionamount) as nFISpend
		FROM nfi.Relational.[Partner] p
		INNER JOIN nfi.Relational.PartnerTrans pt WITH (NOLOCK) ON p.PartnerID = pt.PartnerID
		WHERE pt.TransactionDate BETWEEN @StartDate AND @EndDate
		GROUP BY p.PartnerID, p.PartnerName
	) s
	GROUP BY PartnerID
	ORDER BY PartnerID

END