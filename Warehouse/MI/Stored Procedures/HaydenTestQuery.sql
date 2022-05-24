
-- =============================================
-- Author:		<Hayden>

-- =============================================
CREATE PROCEDURE [MI].[HaydenTestQuery] 
	(
		@startDate date,
		@endDate date
	)
AS
BEGIN
	SET NOCOUNT ON;

	SELECT SUM(TransactionAmount) AS Total
		,p.PartnerName 
	FROM relational.PartnerTrans pt
	INNER JOIN Relational.[Partner] p on p.PartnerID = pt.PartnerID
	WHERE p.PartnerID in (3960,4513,4514) 
		AND TransactionDate BETWEEN @startDate AND @endDate
	GROUP BY p.PartnerName

	

END

