-- Panless successful trans
-- Failed Panlesss == failed trans
-- AMEX csv == tables
-- SchemeTrans

CREATE PROCEDURE [Staging].[AmexTransactionComparison_PanlessTrans_Fetch]
AS
BEGIN

	IF OBJECT_ID('tempdb..#FailedTrans') IS NOT NULL
		DROP TABLE #FailedTrans

	SELECT 
		apw.ID
		, SUM(fp.Price) as spend
		, apw.rw
		, r.FailureReason AS CommonFailureReason
	INTO #FailedTrans
	FROM [SLC_REPL].[RAS].[FailedPANlessTransaction] fp
	LEFT JOIN [SLC_REPL].[RAS].[PANless_Transaction] sp
		ON sp.FailedPANlessTransactionID = fp.FailedPANlessTransactionID
	JOIN Warehouse.Staging.AmexTransactionComparison_APW apw
		ON apw.AmexOfferID = fp.OfferCode
		AND fp.TransactionDate BETWEEN apw.StartDate AND apw.RunningEndDate
	CROSS APPLY (
		SELECT TOP 1
			ISNULL(NULLIF(SUBSTRING(FailureReason, 0, CHARINDEX(':', FailureReason)), ''), FailureReason)
			, COUNT(1)
		FROM [SLC_REPL].[RAS].[FailedPANlessTransaction] xp
		WHERE xp.OfferCode = apw.AmexOfferID
			AND xp.TransactionDate BETWEEN apw.StartDate AND apw.RunningEndDate
		GROUP BY ISNULL(NULLIF(SUBSTRING(FailureReason, 0, CHARINDEX(':', FailureReason)), ''), FailureReason)
		ORDER BY 2 DESC
	) r(FailureReason, Cnt)
	WHERE sp.ID IS NULL
	GROUP BY apw.ID, apw.rw, r.FailureReason

	IF OBJECT_ID('tempdb..#SuccessfulTrans') IS NOT NULL
		DROP TABLE #SuccessfulTrans
	SELECT
		apw.ID
		, SUM(Price) as spend
		, apw.rw
	INTO #SuccessfulTrans
	FROM [SLC_REPL].[RAS].[PANless_Transaction] fp
	JOIN Warehouse.Staging.AmexTransactionComparison_APW apw
		ON apw.AmexOfferID = fp.OfferCode
		AND fp.TransactionDate BETWEEN apw.StartDate AND apw.RunningEndDate
	GROUP BY apw.ID, apw.rw

	SELECT 
		apw.*
		, st.spend PanlessTrans
		, ft.spend Failed_PanlessTrans
		, CommonFailureReason
	FROM Warehouse.Staging.AmexTransactionComparison_APW apw
	LEFT JOIN #FailedTrans ft
		ON ft.ID = apw.ID
	LEFT JOIN #SuccessfulTrans st
		ON st.ID = apw.ID

END
