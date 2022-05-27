CREATE proc [gas].[GetTransactionHistoryForMember_V1] 
	@FanID INT,
	@StartDate SMALLDATETIME,
	@EndDate SMALLDATETIME,
	@Detailed TINYINT=0
AS
SET NOCOUNT ON

DECLARE @CINID INT

SELECT @CINID = c.CINID
FROM SLC_Report.dbo.Fan f WITH (NOLOCK)
INNER JOIN [Relational].[CINList] c WITH (NOLOCK) on f.SourceUID = c.CIN
WHERE f.ID = @FanID

IF @Detailed = 0
BEGIN
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
			c.Amount AS [TransactionValue]
		FROM c
			INNER JOIN Relational.ConsumerCombination cc WITH (NOLOCK) on c.ConsumerCombinationID = cc.ConsumerCombinationID
			INNER JOIN Relational.Location l WITH (NOLOCK) ON C.LocationID = l.LocationID
			INNER JOIN Relational.MCCList m WITH (NOLOCK) ON cc.MCCID = m.MCCID
			INNER JOIN SLC_Report..NobleFiles f WITH (NOLOCK) ON c.FileID = f.ID
			INNER JOIN Archive.dbo.NobleTransactionHistory h WITH (NOLOCK) ON c.FileID = h.FileID and c.RowNum = h.RowNum
			INNER JOIN SLC_Report.dbo.PaymentCard pc WITH (NOLOCK) ON h.PaymentCardID = pc.id
		WHERE (h.MatchId IS NULL) OR (h.MatchId IS NOT NULL AND h.MatchStatus <> 1)
		ORDER BY c.TranDate
	END
ELSE
BEGIN
	;WITH c
	AS
	(
		SELECT FileID, RowNum
		FROM Relational.ConsumerTransaction WITH (NOLOCK)
		WHERE CINID = @CINID AND TranDate BETWEEN @StartDate AND @EndDate

		UNION

		SELECT FileID, RowNum
		FROM Relational.ConsumerTransactionHolding WITH (NOLOCK)
		WHERE CINID = @cINID AND TranDate BETWEEN @StartDate AND @EndDate
	)
	SELECT
			h.FileID,
			h.RowNum,
			h.BankID,
			h.ClearStatus,
			h.MerchantID,
			h.LocationName,
			h.LocationAddress,
			h.LocationCountry,
			h.MCC,
			h.CardholderPresentData,
			h.TranDate,
			h.PostFPInd,
			h.PostStatus,
			h.PaymentCardID,
			h.PanID,
			h.RetailOutletID,
			h.IronOfferMemberID,
			h.MatchID,
			h.BillingRuleID,
			h.MarketingRuleID,
			h.CompositeID,
			h.MatchStatus,
			h.FanID,
			h.RewardStatus,
			h.Amount,
			f.InDate
	FROM c
		INNER JOIN SLC_Report..NobleFiles f WITH (NOLOCK) ON c.FileID = f.ID
		INNER JOIN Archive.dbo.NobleTransactionHistory h WITH (NOLOCK) ON c.FileID = h.FileID and c.RowNum = h.RowNum
	ORDER BY h.TranDate
END
GO
GRANT EXECUTE
    ON OBJECT::[gas].[GetTransactionHistoryForMember_V1] TO [Tony]
    AS [dbo];

