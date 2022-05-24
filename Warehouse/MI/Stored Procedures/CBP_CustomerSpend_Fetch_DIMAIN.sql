CREATE PROCEDURE [MI].[CBP_CustomerSpend_Fetch_DIMAIN]
/*
Amended CJM 20180711 taken from SSIS package
*/       
AS
BEGIN

	SET NOCOUNT ON;

	TRUNCATE TABLE MI.CBP_CustomerSpend;

	INSERT INTO MI.CBP_CustomerSpend (FanID, PaymentMethodID, TransCount, TransAmount)
	SELECT FanID, PaymentMethodID, COUNT(DISTINCT SchemeTransID) AS TransCount, SUM(TransAmount) AS TransAmount
    FROM ( -- s
        SELECT u.SchemeTransID, pt.FanID, pt.PaymentMethodID, pt.TransactionAmount As TransAmount
        FROM Relational.PartnerTrans pt
        INNER JOIN MI.SchemeTransUniqueID u ON pt.MatchID = u.MatchID
        WHERE pt.EligibleForCashback = 1

        UNION ALL

        SELECT u.SchemeTransID, a.FanID, a.PaymentMethodID, a.Amount AS TransAmount 
        FROM ( -- a
                SELECT FileID, RowNum, FanID, PaymentMethodID, Amount 
                FROM Relational.AdditionalCashbackAward 
                WHERE MatchID IS NULL 
                GROUP BY FileID, RowNum, FanID, PaymentMethodID, Amount
		) a
		INNER JOIN MI.SchemeTransUniqueID u ON a.FileID = u.FileID AND a.RowNum = u.RowNum
	) s
	GROUP BY FanID, PaymentMethodID;

END
