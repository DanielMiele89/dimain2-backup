-- =============================================
-- Author:		JEA
-- Create date: 06/06/2016
-- Description:	Loads control stats
-- =============================================
CREATE PROCEDURE [APW].[ControlMethod_ControlStats_Load] 

AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @MonthDate DATE
	SET @MonthDate = DATEADD(MONTH,-1,DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1))

	DECLARE @Cardholders INT

	SELECT @Cardholders = COUNT(*)
	FROM APW.ControlAdjusted

	INSERT INTO APW.ControlStats(MonthDate
		, RetailerID
		, RR
		, SPS
		, ATV
		, ATF
		, ChannelType
		)
	SELECT @MonthDate AS MonthDate 
		, s.PartnerID AS RetailerID
		, SUM(s.adj_Spenders)/@Cardholders AS RR
		, SUM(s.adj_Spend)/SUM(s.adj_Spenders) AS SPS
		, SUM(s.adj_Spend)/SUM(s.adj_Txns) AS ATV
		, SUM(s.adj_Txns)/SUM(s.adj_Spenders) AS ATF
		, s.IsOnline AS ChannelType
	FROM APW.ControlRetailerSpend s
	--WHERE (s.PartnerID != 4138 or s.IsOnline is null or s.IsOnline = 1) --TEST
	GROUP BY s.PartnerID, s.IsOnline
	ORDER BY PartnerID, ChannelType

END