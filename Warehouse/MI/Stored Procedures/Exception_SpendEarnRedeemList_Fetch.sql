-- =============================================
-- Author:		JEA
-- Create date: 13/03/2014
-- Description:	List details for customers who have passed 
-- any of the exception audit test
-- =============================================
CREATE PROCEDURE [MI].[Exception_SpendEarnRedeemList_Fetch]
	
AS
BEGIN

	SET NOCOUNT ON;
	
	CREATE TABLE #ExceptionFanList(ID INT PRIMARY KEY IDENTITY, FanID INT NOT NULL, ExceptionType TINYINT NOT NULL)

	INSERT INTO #ExceptionFanList(FanID, ExceptionType)
	SELECT DISTINCT FanID,1 --high spender with a retailer
	FROM
	(
		SELECT FanID, PartnerID, SUM(TransactionAmount) AS Spend, MONTH(AddedDate) AS AddMonth, YEAR(AddedDate) AS AddYear
		FROM Relational.PartnerTrans
		WHERE AddedDate >= '2013-08-08' --from launch
		GROUP BY FanID, PartnerID, MONTH(AddedDate), YEAR(AddedDate)
		HAVING SUM(TransactionAmount) >= 2500 --£2,000 or over in a month with any brand
	) p
	
	UNION
	
	SELECT DISTINCT FanID, 2 --high earner
	FROM
	(
		SELECT FanID, MONTH(AddedDate) As AddedMonth, YEAR(AddedDate) AS AddedYear
		FROM Relational.PartnerTrans pt
		WHERE AddedDate >= '2013-08-08' --from launch
		GROUP BY FanID, MONTH(AddedDate), YEAR(AddedDate)
		HAVING SUM(CashbackEarned) > 50
	) r

    SELECT CAST(1 AS TINYINT) AS LineType 
		, c.SourceUID AS CIN
		, p.PartnerName
		, MONTH(AddedDate) AS AddMonth
		, YEAR(AddedDate) AS AddYear
		, SUM(TransactionAmount) AS Spend
		, SUM(CashbackEarned) AS Earnings
		, CAST(0 AS MONEY) AS Redemptions
		, COUNT(1) AS ItemCount
		, CAST(CASE WHEN SUM(TransactionAmount) >= 2500 THEN 1 
			WHEN SUM(CashbackEarned) > 50 THEN 1 ELSE 0 END AS INT) AS ExceptionCount
		, e.ExceptionType
	FROM Relational.PartnerTrans T
	INNER JOIN Relational.Customer C ON t.FanID = c.FanID
	INNER JOIN Relational.[Partner] p ON T.PartnerID = P.PartnerID
	INNER JOIN #ExceptionFanList e ON C.FanID = E.FanID
	WHERE t.AddedDate >= '2013-08-08'
	GROUP BY c.SourceUID
		, p.PartnerName
		, p.PartnerID
		, MONTH(AddedDate)
		, YEAR(AddedDate)
		, e.ExceptionType

	UNION

	SELECT CAST(2 AS TINYINT) AS LineType
		, c.SourceUID AS CIN
		, ISNULL(p.PartnerName, '') AS PartnerName
		, MONTH(RedeemDate) AS AddMonth
		, YEAR(RedeemDate) AS AddYear
		, CAST(0 AS MONEY) AS Spend
		, CAST(0 AS MONEY) AS Earnings
		, SUM(r.CashbackUsed) AS Redemptions
		, COUNT(1) AS ItemCount
		, CASE WHEN COUNT(1) > 5 THEN 1 ELSE 0 END AS ExceptionCount
		, e.ExceptionType
	FROM Relational.Redemptions r
	INNER JOIN Relational.Customer c on r.FanID = c.FanID
	LEFT OUTER JOIN Relational.[Partner] p ON r.PartnerID = p.PartnerID
	INNER JOIN #ExceptionFanList e ON C.FanID = E.FanID
	WHERE r.RedeemDate >= '2013-08-08'
	GROUP BY c.SourceUID
		, p.PartnerName
		, MONTH(RedeemDate)
		, YEAR(RedeemDate)
		, e.ExceptionType

	UNION

	SELECT CAST(3 AS TINYINT) AS LineType
		, c.SourceUID AS CIN
		, 'Cashback Award' AS PartnerName
        , MONTH(t.[Date]) AS AddMonth
		, YEAR(t.[Date]) AS AddYear
		, CAST(0 AS MONEY) AS Spend
        , SUM(t.ClubCash*tt.Multiplier) as Earnings
        , CAST(0 AS MONEY) AS Redemptions
		, CAST(0 AS INT) AS ItemCount
		, CAST(0 AS INT) AS ExceptionCount
		, e.ExceptionType
	FROM slc_report.dbo.trans as t with (nolock)
	INNER JOIN slc_report.dbo.TransactionType as TT with (noLock) ON t.TypeID = TT.ID
	INNER JOIN Relational.Customer c ON t.FanID = c.FanID
	INNER JOIN #ExceptionFanList e ON c.FanID = e.FanID
	WHERE t.TypeID in (1,17)
	AND t.[Date] >= '2013-08-08'
	GROUP BY c.SourceUID
		, MONTH(t.[Date])
		, YEAR(t.[Date])
		, e.ExceptionType

	ORDER BY ExceptionType
		, CIN
		, AddYear
		, AddMonth
		, LineType
		, PartnerName

	DROP TABLE #ExceptionFanList

END