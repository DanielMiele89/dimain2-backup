-- =============================================
-- Author:		JEA
-- Create date: 23/10/2014
-- Description:	Retrieves cross-check information for the financial report
-- =============================================
CREATE PROCEDURE MI.EarnRedeemFinance_CrossCheck_Fetch
	
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @MonthDate DATE

	IF MONTH(GETDATE()) < 6
	BEGIN
		SET @MonthDate = DATEFROMPARTS(YEAR(GETDATE()) -1,4,1) --if the report is run before June, the financial year dates from the previous May.
	END
	ELSE
	BEGIN
		SET @MonthDate = DATEFROMPARTS(YEAR(GETDATE()),4,1) --if the report is run in or after June, the financial year dates from the current May.
	END

	CREATE TABLE #MonthDates(MonthDate DATE PRIMARY KEY)

	INSERT INTO #MonthDates(MonthDate)

	SELECT RedeemMonthDate AS MonthDate
	FROM MI.EarnRedeemFinance_CrossCheck_Redemptions

	UNION

	SELECT EarnMonthDate  AS MonthDate
	FROM MI.EarnRedeemFinance_CrossCheck_AdditionalEarnings

	UNION

	SELECT AwardMonthDate  AS MonthDate
	FROM MI.EarnRedeemFinance_CrossCheck_CashbackAwards

	UNION

	SELECT EarnMonthDate  AS MonthDate
	FROM MI.EarnRedeemFinance_CrossCheck_PartnerEarnings

	ORDER BY MonthDate

	SELECT CAST(NULL AS DATE) AS MonthDate
		, CAST(1 AS BIT) AS IsPrevious
		, ISNULL(SUM(p.Earnings),0) AS PartnerEarnings
		, ISNULL(SUM(a.Earnings),0) AS AdditionalEarnings
		, ISNULL(SUM(c.Awards),0) AS CashbackAwards
		, ISNULL(SUM(r.Redemption),0) AS Redemptions
	FROM #MonthDates m
	LEFT OUTER JOIN MI.EarnRedeemFinance_CrossCheck_PartnerEarnings p ON m.MonthDate = p.EarnMonthDate
	LEFT OUTER JOIN MI.EarnRedeemFinance_CrossCheck_AdditionalEarnings a ON m.MonthDate = a.EarnMonthDate
	LEFT OUTER JOIN MI.EarnRedeemFinance_CrossCheck_CashbackAwards c ON m.MonthDate = c.AwardMonthDate
	LEFT OUTER JOIN MI.EarnRedeemFinance_CrossCheck_Redemptions r ON m.MonthDate = r.RedeemMonthDate
	WHERE m.MonthDate <= @MonthDate

	UNION

	SELECT M.MonthDate
		, CAST(0 AS BIT) AS IsPrevious
		, ISNULL(p.Earnings,0) AS PartnerEarnings
		, ISNULL(a.Earnings,0) AS AdditionalEarnings
		, ISNULL(c.Awards,0) AS CashbackAwards
		, ISNULL(r.Redemption,0) AS Redemptions
	FROM #MonthDates m
	LEFT OUTER JOIN MI.EarnRedeemFinance_CrossCheck_PartnerEarnings p ON m.MonthDate = p.EarnMonthDate
	LEFT OUTER JOIN MI.EarnRedeemFinance_CrossCheck_AdditionalEarnings a ON m.MonthDate = a.EarnMonthDate
	LEFT OUTER JOIN MI.EarnRedeemFinance_CrossCheck_CashbackAwards c ON m.MonthDate = c.AwardMonthDate
	LEFT OUTER JOIN MI.EarnRedeemFinance_CrossCheck_Redemptions r ON m.MonthDate = r.RedeemMonthDate
	WHERE m.MonthDate > @MonthDate

	ORDER BY MonthDate

	DROP TABLE #MonthDates

END