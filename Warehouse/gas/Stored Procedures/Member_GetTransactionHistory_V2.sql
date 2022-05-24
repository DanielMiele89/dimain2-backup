CREATE PROC [gas].[Member_GetTransactionHistory_V2] 
	@FanID INT,
	@StartDate SMALLDATETIME,
	@EndDate SMALLDATETIME,
	@PageNumber INT = 1,
	@PageSize INT = 10
AS
SET NOCOUNT ON

DECLARE @CINID INT

SELECT @CINID = c.CINID
FROM SLC_Report.dbo.Fan f WITH (NOLOCK)
INNER JOIN [Relational].[CINList] c WITH (NOLOCK) on f.SourceUID = c.CIN
WHERE f.ID = @FanID

;WITH c
AS
(
	SELECT FileID, RowNum, ConsumerCombinationID, LocationID, TranDate, Amount
	FROM Relational.ConsumerTransaction WITH (NOLOCK)
	WHERE CINID = @CINID AND TranDate BETWEEN @StartDate AND @EndDate

	UNION

	SELECT FileID, RowNum, ConsumerCombinationID, LocationID, TranDate, Amount
	FROM Relational.ConsumerTransactionHolding WITH (NOLOCK)
	WHERE CINID = @CINID AND TranDate BETWEEN @StartDate AND @EndDate
)
SELECT 
	'****' + RIGHT(pc.MaskedCardNumber,4) as CardNo,
	c.TranDate AS [DateofPurchase],
	CONVERT(DATE,f.InDate) AS [DateReceived],
	CASE 
		WHEN c.Amount > 0 THEN 'Spend'
		ELSE 'Refund'
	END AS [TransactionType],
	cc.MID,
	cc.Narrative,
	l.LocationAddress,
	cc.LocationCountry,
	m.MCC,
	c.Amount AS [TransactionValue],
	h.CardInputMode,
	CASE 
		WHEN h.CardInputMode IN ('A','M') THEN 'Debit - contactless'
		ELSE 'Debit'
	END AS TransactionMethod,
	COUNT(1) OVER(PARTITION BY '') AS TotalRows
FROM c
	INNER JOIN Relational.ConsumerCombination cc WITH (NOLOCK) on c.ConsumerCombinationID = cc.ConsumerCombinationID
	INNER JOIN Relational.Location l WITH (NOLOCK) ON C.LocationID = l.LocationID
	INNER JOIN Relational.MCCList m WITH (NOLOCK) ON cc.MCCID = m.MCCID
	INNER JOIN SLC_Report..NobleFiles f WITH (NOLOCK) ON c.FileID = f.ID
	INNER JOIN Archive.dbo.NobleTransactionHistory h WITH (NOLOCK) ON c.FileID = h.FileID and c.RowNum = h.RowNum
	INNER JOIN SLC_Report.dbo.PaymentCard pc WITH (NOLOCK) ON h.PaymentCardID = pc.id
WHERE (h.MatchId IS NULL) OR (h.MatchId IS NOT NULL AND h.MatchStatus <> 1)
ORDER BY c.TranDate
OFFSET ((@PageNumber - 1) * @PageSize) ROWS
FETCH NEXT @PageSize ROWS ONLY