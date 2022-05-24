-- =============================================
-- Author:		JEA
-- Create date: 04/08/2014
-- Description:	Fetches the weekly measurements
-- for the daily scheme stats report by transaction date
-- =============================================
CREATE PROCEDURE [MI].[SchemeStats_Weekly_TranDate_Fetch]

AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @Date DATE, @DateTime DATETIME, @QuidcoCheckDate DATE

		--JEA 07/05/2015 - New algorithm to account for differential receipt of debit and credit card data
	SELECT @Date = MAX(TransactionDate)
	FROM
	(
		SELECT TransactionDate, TranCount, SUM(TranCount) OVER (ORDER BY Transactiondate ROWS BETWEEN 30 PRECEDING AND CURRENT ROW)/30 AS TranAvg
		FROM
		(
			SELECT TransactionDate, CAST(COUNT(*) AS FLOAT) As TranCount
			FROM Relational.PartnerTrans
			WHERE TransactionDate >= DATEADD(MONTH, -2, GETDATE())
			GROUP BY TransactionDate
		) T
	) t
	WHERE TranCount/TranAvg >= 0.6

	SELECT @QuidcoCheckDate = MAX(Match.TransactionDate)
	FROM SLC_Report.dbo.Match
	INNER JOIN SLC_Report.dbo.Pan p ON Match.PanID = p.ID
	INNER JOIN SLC_Report.dbo.Fan f ON p.CompositeID = f.CompositeID
	INNER JOIN Trans t on t.MatchID = match.ID
	WHERE f.ClubID = 12 			
		AND Match.[status] = 1-- Valid transaction status

	IF @Date > @QuidcoCheckDate
	BEGIN
		SET @Date = @QuidcoCheckDate
	END

	SET @DateTime = DATEADD(MINUTE, -1, DATEADD(DAY, 1, CAST(@Date AS DATETIME)))
	
	SELECT TransactionDate AS TranDate
		, Spend
		, SUM(Spend) OVER (ORDER BY TransactionDate ROWS 6 PRECEDING) AS SpendWeek
	FROM
	(
		SELECT TransactionDate
		, CASE WHEN TransactionDate = @Date THEN Spend * 1.01 ELSE Spend END AS Spend
		FROM
		(

			SELECT TransactionDate
				, SUM(TransactionAmount) AS Spend
			FROM
			(
				SELECT TransactionDate
					, TransactionAmount
				FROM Relational.PartnerTrans
				WHERE TransactionDate BETWEEN '2013-08-08' AND @Date
					AND PartnerID != 4433
					AND PartnerID != 4447
		
				UNION ALL

				SELECT CAST(m.TransactionDate AS DATE) AS TransactionDate
					, ISNULL(m.Amount, 0) AS Spend
				FROM SLC_Report.dbo.Match m
				INNER JOIN SLC_Report.dbo.Pan p ON m.PanID = p.ID
				INNER JOIN SLC_Report.dbo.Fan f ON p.CompositeID = f.CompositeID
				INNER JOIN Trans t on t.MatchID = match.ID
				WHERE f.ClubID = 12 			
					AND m.[status] = 1-- Valid transaction status
					AND m.TransactionDate BETWEEN '2013-08-08' AND @DateTime
			) r
			GROUP BY TransactionDate
		) t
	) t
	ORDER BY TransactionDate DESC

END
