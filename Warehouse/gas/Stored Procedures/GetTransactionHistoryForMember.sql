CREATE PROC [gas].[GetTransactionHistoryForMember] 
	@FanID INT,
	@TransactionType TINYINT, --0 - All; 1 - Credit; 2 - Debit; NB: Credit 1 maps to Warehouse-PaymentTypeID 2, Credit 2 maps to Warehouse-PaymentTypeID 1
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
			SELECT FileID, RowNum, ConsumerCombinationID, LocationID, TranDate, Amount, PaymentTypeID
			FROM Relational.ConsumerTransaction WITH (NOLOCK)
			WHERE CINID = @CINID AND TranDate BETWEEN @StartDate AND @EndDate

			UNION

			SELECT FileID, RowNum, ConsumerCombinationID, LocationID, TranDate, Amount, PaymentTypeID
			FROM Relational.ConsumerTransactionHolding WITH (NOLOCK)
			WHERE CINID = @CINID AND TranDate BETWEEN @StartDate AND @EndDate
		),
	t AS
	(
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
				WHEN h.CardInputMode IN ('A','M') THEN 'Debit - Contactless'
				ELSE 'Debit'
			END AS TransactionMethod,
			c.PaymentTypeID
			FROM c
			INNER JOIN Relational.ConsumerCombination cc WITH (NOLOCK) on c.ConsumerCombinationID = cc.ConsumerCombinationID
			INNER JOIN Relational.Location l WITH (NOLOCK) ON C.LocationID = l.LocationID
			INNER JOIN Relational.MCCList m WITH (NOLOCK) ON cc.MCCID = m.MCCID
			INNER JOIN SLC_Report..NobleFiles f WITH (NOLOCK) ON c.FileID = f.ID
			INNER JOIN Archive_Light.dbo.NobleTransactionHistory h WITH (NOLOCK) ON c.FileID = h.FileID and c.RowNum = h.RowNum and c.PaymentTypeID = 1 --Debit card transaction
			INNER JOIN SLC_Report.dbo.PaymentCard pc WITH (NOLOCK) ON h.PaymentCardID = pc.id
		WHERE (h.MatchId IS NULL) OR (h.MatchId IS NOT NULL AND h.MatchStatus <> 1)
		
		UNION

		SELECT 
			'****' + RIGHT(pc.MaskedCardNumber,4) as CardNo,
			c.TranDate AS [DateofPurchase],
			CONVERT(DATE,f.InDate) AS [DateReceived],
			CASE 
				WHEN c.Amount > 0 AND h.ClassCode = 'PR' THEN 'Spend'
				WHEN h.ChargebackIndicator = 'Y' THEN 'Chargeback'
				WHEN h.ClassCode = 'FE' THEN 'Fee'
				WHEN h.ClassCode = 'PY' THEN 'Payment'
				WHEN h.ClassCode = 'CA' THEN 'Cash'
				ELSE 'Refund' --c.Amount <= 0 AND h.ClassCode = 'PR' AND h.ChargebackIndicator <> 'Y'
			END AS [TransactionType],
			cc.MID,
			cc.Narrative,
			l.LocationAddress,
			cc.LocationCountry,
			m.MCC,
			c.Amount AS [TransactionValue],
			h.TerminalEntry AS CardInputMode,
			CASE 
				WHEN h.TerminalEntry IN ('07','91') THEN 'Credit - Contactless'
				ELSE 'Credit'
			END AS TransactionMethod,
			c.PaymentTypeID
		FROM c
			INNER JOIN Relational.ConsumerCombination cc WITH (NOLOCK) on c.ConsumerCombinationID = cc.ConsumerCombinationID
			INNER JOIN Relational.Location l WITH (NOLOCK) ON C.LocationID = l.LocationID
			INNER JOIN Relational.MCCList m WITH (NOLOCK) ON cc.MCCID = m.MCCID
			INNER JOIN SLC_Report..NobleFiles f WITH (NOLOCK) ON c.FileID = f.ID
			INNER JOIN Archive_Light.dbo.CBP_Credit_TransactionHistory h WITH (NOLOCK) ON c.FileID = h.FileID and c.RowNum = h.RowNum and c.PaymentTypeID = 2 --Crebit card transaction
			INNER JOIN SLC_Report.dbo.PaymentCard pc WITH (NOLOCK) ON h.PaymentCardID = pc.id
		WHERE (h.MatchId IS NULL) OR (h.MatchId IS NOT NULL AND h.MatchStatus <> 1)		
	)	
	SELECT
		CardNo,
		[DateofPurchase],
		[DateReceived],
		[TransactionType],
		MID,
		Narrative,
		LocationAddress,
		LocationCountry,
		MCC,
		[TransactionValue],
		CardInputMode,
		TransactionMethod,
		CONVERT(TINYINT, CASE PaymentTypeID WHEN 1 THEN 2 WHEN 2 THEN 1 ELSE 0 END) AS CardTypeID
	FROM t
		WHERE (@TransactionType = 0) OR (@TransactionType = 1 AND t.PaymentTypeID = 2) OR (@TransactionType = 2 AND t.PaymentTypeID = 1)
	ORDER BY [DateofPurchase]
	END
ELSE
BEGIN
	;WITH c
	AS
	(
		SELECT FileID, RowNum, PaymentTypeID
		FROM Relational.ConsumerTransaction WITH (NOLOCK)
		WHERE CINID = @CINID AND TranDate BETWEEN @StartDate AND @EndDate

		UNION

		SELECT FileID, RowNum, PaymentTypeID
		FROM Relational.ConsumerTransactionHolding WITH (NOLOCK)
		WHERE CINID = @cINID AND TranDate BETWEEN @StartDate AND @EndDate
	),
	t AS
	(
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
			f.InDate,
			h.CardInputMode
	FROM c
		INNER JOIN SLC_Report..NobleFiles f WITH (NOLOCK) ON c.FileID = f.ID
		INNER JOIN Archive_Light.dbo.NobleTransactionHistory h WITH (NOLOCK) ON c.FileID = h.FileID and c.RowNum = h.RowNum and c.PaymentTypeID = 1 --Debit card transaction

	UNION

	SELECT
			h.FileID,
			h.RowNum,
			h.ClientProductCode AS BankID,
			'' AS ClearStatus,
			h.MerchantID,
			h.MerchantDBAName AS LocationName,
			h.MerchantDBACity AS LocationAddress,
			h.MerchantDBACountry AS LocationCountry,
			h.MerchantSICClassCode AS MCC,
			h.CardholderPresentMC AS CardholderPresentData,
			h.TransactionDate AS TranDate,
			'' AS PostFPInd,
			'' AS PostStatus,
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
			f.InDate,
			h.TerminalEntry AS CardInputMode
	FROM c
		INNER JOIN SLC_Report..NobleFiles f WITH (NOLOCK) ON c.FileID = f.ID
		INNER JOIN Archive_Light.dbo.CBP_Credit_TransactionHistory h WITH (NOLOCK) ON c.FileID = h.FileID and c.RowNum = h.RowNum and c.PaymentTypeID = 2 --Credit card transaction


	)
	SELECT *
	FROM t
	ORDER BY TranDate
END