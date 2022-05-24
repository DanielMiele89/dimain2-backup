-- =============================================
-- Author:		AJS
-- Create date: 13/05/2014
-- Description:	inserts details for customers who have passed 
-- any of the exception audit test into MI.Exception_SpendEarnRedeemList
-- =============================================
CREATE PROCEDURE [MI].[Exception_SpendEarnRedeemList_Dates_Refresh]
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

	TRUNCATE TABLE MI.RBSPortal_Exception_SpendEarnRedeemList_DateChoice

	DECLARE @DateChoiceID TINYINT = 0, @StartDate DATE, @EndDate DATE

	WHILE @DateChoiceID <= 3
	BEGIN

		IF @DateChoiceID = 0
		BEGIN
			SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
			SET @EndDate = GETDATE()
		END
		ELSE IF @DateChoiceID = 1
		BEGIN
			SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
			SET @EndDate = DATEADD(DAY, -1, @StartDate)
			SET @StartDate = DATEADD(MONTH, -1, @StartDate)
		END
		ELSE
		BEGIN
			SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
			SET @EndDate = DATEADD(DAY, -1, @StartDate)
			SET @StartDate = DATEADD(MONTH, -3, @StartDate)
		END

		CREATE TABLE #ExceptionFanList(ID INT PRIMARY KEY IDENTITY, FanID INT NOT NULL, ExceptionType TINYINT NOT NULL)

		INSERT INTO #ExceptionFanList(FanID, ExceptionType)
		SELECT DISTINCT FanID,1 --high spender with a retailer
		FROM
		(
			SELECT FanID, PartnerID, SUM(TransactionAmount) AS Spend, MONTH(AddedDate) AS AddMonth, YEAR(AddedDate) AS AddYear
			FROM Relational.PartnerTrans
			WHERE AddedDate BETWEEN @StartDate AND @EndDate
				AND (PartnerID != 3960 OR TransactionAmount >= 150)
			GROUP BY FanID, PartnerID, MONTH(AddedDate), YEAR(AddedDate)
			HAVING SUM(TransactionAmount) >= 2500 --£2,000 or over in a month with any brand
		) p
	
		UNION
	
		SELECT DISTINCT FanID, 2 --high earner
		FROM
		(
			SELECT FanID, MONTH(AddedDate) As AddedMonth, YEAR(AddedDate) AS AddedYear
			FROM Relational.PartnerTrans pt
			WHERE AddedDate BETWEEN @StartDate AND @EndDate --from launch
				AND (PartnerID != 3960 OR TransactionAmount >= 150)
			GROUP BY FanID, MONTH(AddedDate), YEAR(AddedDate)
			HAVING SUM(CashbackEarned) > 50
		) r
		INSERT INTO MI.RBSPortal_Exception_SpendEarnRedeemList_DateChoice (
			DateChoiceID
			,LineType 
			,CIN
			,PartnerName
			,AddMonth
			,AddYear
			,AddedDate
			,Spend
			,Earnings
			,Redemptions
			,ItemCount
			,ExceptionCount
			,ExceptionType)
		SELECT @DateChoiceID 
			, LineType 
			,CIN
			,PartnerName
			,AddMonth
			,AddYear
			,AddedDate
			,Spend
			,Earnings
			,Redemptions
			,ItemCount
			,ExceptionCount
			,ExceptionType
			--into MI.RBSPortal_Exception_SpendEarnRedeemList
			FROM(
		SELECT CAST(1 AS TINYINT) AS LineType 
			, c.SourceUID AS CIN
			, p.PartnerName
			, MONTH(AddedDate) AS AddMonth
			, YEAR(AddedDate) AS AddYear
			, t.AddedDate
			, SUM(TransactionAmount) AS Spend
			, ISNULL(SUM(CashbackEarned), 0) AS Earnings
			, CAST(0 AS MONEY) AS Redemptions
			, COUNT(1) AS ItemCount
			, CAST(CASE WHEN SUM(TransactionAmount) >= 2500 THEN 1 
				WHEN SUM(CashbackEarned) > 50 THEN 1 ELSE 0 END AS INT) AS ExceptionCount
			, e.ExceptionType
		FROM Relational.PartnerTrans T
		INNER JOIN Relational.Customer C ON t.FanID = c.FanID
		INNER JOIN Relational.[Partner] p ON T.PartnerID = P.PartnerID
		INNER JOIN #ExceptionFanList e ON C.FanID = E.FanID
		WHERE t.AddedDate BETWEEN @StartDate AND @EndDate
		GROUP BY c.SourceUID
			, p.PartnerName
			, p.PartnerID
			, MONTH(AddedDate)
			, YEAR(AddedDate)
			, e.ExceptionType
			, t.AddedDate

		UNION

		SELECT CAST(1 AS TINYINT) AS LineType 
			, c.SourceUID AS CIN
			, p.[Description] AS PartnerName
			, MONTH(AddedDate) AS AddMonth
			, YEAR(AddedDate) AS AddYear
			, t.AddedDate
			, SUM(t.Amount) AS Spend
			, ISNULL(SUM(CashbackEarned),0) AS Earnings
			, CAST(0 AS MONEY) AS Redemptions
			, COUNT(1) AS ItemCount
			, CAST(CASE WHEN SUM(t.Amount) >= 2500 THEN 1 
				WHEN SUM(CashbackEarned) > 50 THEN 1 ELSE 0 END AS INT) AS ExceptionCount
			, e.ExceptionType
		FROM Relational.AdditionalCashbackAward T
		INNER JOIN Relational.Customer C ON t.FanID = c.FanID
		INNER JOIN Relational.AdditionalCashbackAwardType p ON T.AdditionalCashbackAwardTypeID = P.AdditionalCashbackAwardTypeID
		INNER JOIN #ExceptionFanList e ON C.FanID = E.FanID
		WHERE t.AddedDate BETWEEN @StartDate AND @EndDate
		GROUP BY c.SourceUID
			, p.[Description]
			, p.AdditionalCashbackAwardTypeID
			, MONTH(AddedDate)
			, YEAR(AddedDate)
			, e.ExceptionType
			, t.AddedDate

		UNION

		SELECT CAST(2 AS TINYINT) AS LineType
			, c.SourceUID AS CIN
			, ISNULL(p.PartnerName, '') AS PartnerName
			, MONTH(RedeemDate) AS AddMonth
			, YEAR(RedeemDate) AS AddYear
			, CAST(RedeemDate AS Date)
			, CAST(0 AS MONEY) AS Spend
			, ISNULL(CAST(0 AS MONEY),0) AS Earnings
			, SUM(r.CashbackUsed) AS Redemptions
			, COUNT(1) AS ItemCount
			, CASE WHEN COUNT(1) > 5 THEN 1 ELSE 0 END AS ExceptionCount
			, e.ExceptionType
		FROM Relational.Redemptions r
		INNER JOIN Relational.Customer c on r.FanID = c.FanID
		LEFT OUTER JOIN Relational.[Partner] p ON r.PartnerID = p.PartnerID
		INNER JOIN #ExceptionFanList e ON C.FanID = E.FanID
		WHERE r.RedeemDate BETWEEN @StartDate AND @EndDate
		GROUP BY c.SourceUID
			, p.PartnerName
			, MONTH(RedeemDate)
			, YEAR(RedeemDate)
			, CAST(RedeemDate AS DATE)
			, e.ExceptionType

		UNION

		SELECT CAST(3 AS TINYINT) AS LineType
			, c.SourceUID AS CIN
			, 'Cashback Award' AS PartnerName
			, MONTH(t.[Date]) AS AddMonth
			, YEAR(t.[Date]) AS AddYear
			, t.[Date]
			, CAST(0 AS MONEY) AS Spend
			, ISNULL(SUM(t.ClubCash),0) as Earnings
			, CAST(0 AS MONEY) AS Redemptions
			, CAST(0 AS INT) AS ItemCount
			, CAST(0 AS INT) AS ExceptionCount
			, e.ExceptionType
		FROM slc_report.dbo.trans as t with (nolock)
		INNER JOIN (SELECT ID, [Description] AS AwardType
				FROM SLC_Report.dbo.SLCPoints
				WHERE ID < 56 OR ID > 63) p ON t.ItemID = p.ID
		INNER JOIN Relational.Customer c ON t.FanID = c.FanID
		INNER JOIN #ExceptionFanList e ON c.FanID = e.FanID
		WHERE t.clubcash > 0 AND t.matchid IS NULL AND t.TypeID =1
		AND t.[Date] BETWEEN @StartDate AND @EndDate
		GROUP BY c.SourceUID
			, MONTH(t.[Date])
			, YEAR(t.[Date])
			, t.[Date]
			, e.ExceptionType
			)aa
		DROP TABLE #ExceptionFanList

		SET @DateChoiceID = @DateChoiceID + 1

		IF @DateChoiceID = 2
		BEGIN
			SET @DateChoiceID = 3
		END

	END

	
END