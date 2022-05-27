CREATE PROCEDURE [MI].[CBP_CustomerSpend_Fetch]
/*
Amended CJM 20180711 taken from SSIS package
*/       
AS
BEGIN

	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	TRUNCATE TABLE MI.CBP_CustomerSpend;

	INSERT INTO MI.CBP_CustomerSpend WITH (TABLOCK)
		(FanID, PaymentMethodID, TransCount, TransAmount)
	SELECT 
		FanID = ISNULL(p.FanID, s.FanID), 
		PaymentMethodID = ISNULL(p.PaymentMethodID, s.PaymentMethodID),
		TransCount = ISNULL(p.TransCount,0) + ISNULL(s.TransCount,0), 
		TransAmount = ISNULL(p.TransAmount,0) + ISNULL(s.TransAmount,0)
	FROM (
		SELECT pt.FanID, pt.PaymentMethodID, TransCount = COUNT(*), TransAmount = SUM(pt.TransactionAmount)
		FROM MI.SchemeTransUniqueID u
		INNER JOIN Relational.PartnerTrans pt  
			ON pt.MatchID = u.MatchID
		WHERE pt.EligibleForCashback = 1
		GROUP BY pt.FanID, pt.PaymentMethodID
	) p
	FULL OUTER JOIN (
		SELECT a.FanID, a.PaymentMethodID, TransCount = COUNT(*), TransAmount = SUM(a.Amount) 
		FROM MI.SchemeTransUniqueID u
		INNER JOIN ( -- a
			SELECT FileID, RowNum, FanID, PaymentMethodID, Amount 
			FROM Relational.AdditionalCashbackAward 
			WHERE MatchID IS NULL 
			GROUP BY FileID, RowNum, FanID, PaymentMethodID, Amount
		) a
		ON a.FileID = u.FileID AND a.RowNum = u.RowNum
			AND u.MatchID IS NULL
		GROUP BY a.FanID, a.PaymentMethodID
	) s
	ON s.FanID = p.FanID 
		AND s.PaymentMethodID = p.PaymentMethodID
	ORDER BY FanID, PaymentMethodID
	-- (7,386,661 rows affected) / 00:26:31

END
