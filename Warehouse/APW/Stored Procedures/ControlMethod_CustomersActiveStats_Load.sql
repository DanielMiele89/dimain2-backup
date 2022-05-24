-- =============================================
-- Author:		JEA
-- Create date: 15/06/2016
-- Description:	Loads customer active stats
-- =============================================
CREATE PROCEDURE [APW].[ControlMethod_CustomersActiveStats_Load] 

AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @MonthDate DATE
	SET @MonthDate = DATEADD(MONTH,-1,DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1))

	DECLARE @Cardholders INT

	SELECT @Cardholders = COUNT(*)
	FROM APW.CustomersActive

	INSERT INTO APW.CustomersActiveStats(MonthDate
		, RetailerID
		, RR
		, SPS
		, ATV
		, ATF
		, ChannelType
		)
	SELECT @MonthDate AS MonthDate 
		, s.PartnerID AS RetailerID
		, s.SpenderCount/@Cardholders AS RR
		, CASE WHEN s.SpenderCount < 1 THEN 0 ELSE s.Spend/s.SpenderCount END AS SPS
		, CASE WHEN s.TranCount < 1 THEN 0 ELSE s.Spend/s.TranCount END AS ATV
		, CASE WHEN s.SpenderCount < 1 THEN 0 ELSE s.TranCount/s.SpenderCount END AS ATF
		, s.IsOnline AS ChannelType
	FROM APW.CustomersActiveRetailerSpend s
	ORDER BY RetailerID, ChannelType

END