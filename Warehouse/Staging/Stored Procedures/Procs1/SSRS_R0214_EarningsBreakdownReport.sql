CREATE PROC [Staging].[SSRS_R0214_EarningsBreakdownReport] AS 
 BEGIN 
	SET NOCOUNT ON;
/*******************************************************************************************************************************************
	1. Declare Variables
*******************************************************************************************************************************************/
	DECLARE @PrevMonthStart DATE = DATEADD(MONTH,DATEDIFF(MONTH,0, GETDATE())-1, 0);
	DECLARE @PrevMonthEnd   DATE = DATEADD(MONTH,DATEDIFF(MONTH,-1,GETDATE())-1,-1);

/*******************************************************************************************************************************************
	2. Fetch all required AdditionalCashbackAwardTypes grouped by Trandate
*******************************************************************************************************************************************/
			;With DirectDebit AS (
					SELECT TranDate,
							SUM(ACA.CashbackEarned) AS DirectDebitAmount
					FROM Relational.AdditionalCashbackAward ACA
					WHERE TranDate BETWEEN @PrevMonthStart AND @PrevMonthEnd
					AND AdditionalCashbackAwardTypeID IN (8,10,25,37)
					GROUP BY TranDate
			),
			Mobile AS (
					SELECT TranDate,
							SUM(ACA.CashbackEarned) AS MobileAmount
					FROM Relational.AdditionalCashbackAward ACA
					WHERE TranDate BETWEEN @PrevMonthStart AND @PrevMonthEnd
					AND AdditionalCashbackAwardTypeID IN (38)
					GROUP BY TranDate
			)
			,CreditCardSuperMarket AS (
					SELECT TranDate,
							SUM(ACA.CashbackEarned) AS CreditCardSuperMarketAmount
					FROM Relational.AdditionalCashbackAward ACA
					WHERE TranDate BETWEEN @PrevMonthStart AND @PrevMonthEnd
					AND AdditionalCashbackAwardTypeID IN (2)
					GROUP BY TranDate
			)
			,CreditCardOther AS (
					SELECT TranDate,
							SUM(ACA.CashbackEarned) AS CreditCardOtherAmount
					FROM Relational.AdditionalCashbackAward ACA
					WHERE TranDate BETWEEN @PrevMonthStart AND @PrevMonthEnd
					AND AdditionalCashbackAwardTypeID IN (3)
					GROUP BY TranDate
			)
			--,CreditCard AS (
			--		SELECT TranDate,
			--			 SUM(ACA.CashbackEarned) AS CreditCardAmount
			--		FROM Relational.AdditionalCashbackAward ACA
			--		WHERE TranDate BETWEEN '20201201' AND '20201231'
			--		AND AdditionalCashbackAwardTypeID NOT IN (37,38)
			--		GROUP BY TranDate
			--)
			,Retailer AS(
				SELECT TransactionDate, SUM(CashbackEarned) As RetailerAmount
				FROM Relational.PartnerTrans PT
				WHERE TransactionDate BETWEEN @PrevMonthStart AND @PrevMonthEnd
				GROUP BY TransactionDate
			)
			SELECT RA.TransactionDate, RA.RetailerAmount, DD.DirectDebitAmount, M.MobileAmount, CCS.CreditCardSuperMarketAmount, CCO.CreditCardOtherAmount--, CC.CreditCardAmount
			FROM Retailer RA
			LEFT JOIN DirectDebit DD ON DD.TranDate = RA.TransactionDate
			LEFT JOIN Mobile M ON M.TranDate = RA.TransactionDate
			LEFT JOIN CreditCardSuperMarket CCS ON CCS.TranDate = RA.TransactionDate
			LEFT JOIN CreditCardOther CCO ON CCO.TranDate = RA.TransactionDate
			--LEFT JOIN CreditCard CC ON CC.TranDate = RA.TransactionDate
			ORDER BY RA.TransactionDate
END