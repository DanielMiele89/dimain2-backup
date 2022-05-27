-- =============================================
-- Author:		JEA
-- Create date: 16/10/2014
-- Description:	Sources earnings for EarnRedeemFinance report
-- =============================================
CREATE PROCEDURE [MI].[EarnRedeemFinance_EarningsCashbackAward_Fetch] 
	(
		@IsMonthEnd BIT = 1
	)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @EndDate DATETIME

	IF @IsMonthEnd = 1
	BEGIN
		SET @EndDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
	END
	ELSE
	BEGIN
		SET @EndDate = GETDATE()
	END

	----cashback awards
	SELECT c.FanID
		, CAST(0 AS SMALLINT) AS BrandID
		, t.[Date] AS TransactionDate
		, t.ClubCash AS EarnAmount
		, t.[Date] As EligibleDate
		, CAST(255 AS TINYINT) AS ChargeTypeID
		, CAST(255 AS TINYINT) AS PaymentMethodID
		, CAST(CASE WHEN c.ClubID = 138 THEN 1 ELSE 0 END AS BIT) AS IsRBS
		, p.AwardType
		, t.ClubCash as EarnRedeemable
	FROM slc_report.dbo.trans t
	INNER JOIN (SELECT ID, [Description] AS AwardType
				FROM SLC_Report.dbo.SLCPoints
				WHERE ID < 56 OR ID > 63) p ON t.ItemID = p.ID
	INNER JOIN Relational.Customer c ON t.FanID = c.FanId
	WHERE t.clubcash > 0 AND t.matchid IS NULL AND t.TypeID =1
	AND t.[Date] < @EndDate
	
	ORDER BY TransactionDate

END
