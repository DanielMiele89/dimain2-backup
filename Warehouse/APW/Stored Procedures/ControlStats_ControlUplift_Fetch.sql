-- =============================================
-- Author:		JEA
-- Create date: 15/06/2016
-- Description:	Derives uplift figures from customer and control stats
-- =============================================
CREATE PROCEDURE [APW].[ControlStats_ControlUplift_Fetch] 

AS
BEGIN

	SET NOCOUNT ON;

	SELECT a.MonthDate
		, a.RetailerID
		, CASE WHEN c.RR = 0 THEN 1 ELSE (a.RR-c.RR)/c.RR END AS RRUplift
		, CASE WHEN c.SPS = 0 THEN 1 ELSE (a.SPS-c.SPS)/c.SPS END AS SPSUplift
		, CASE WHEN c.ATV = 0 THEN 1 ELSE (a.ATV-c.ATV)/c.ATV END AS ATVUplift
		, CASE WHEN c.ATF = 0 THEN 1 ELSE (a.ATF-c.ATF)/c.ATF END AS ATFUplift
		, a.ChannelType
	FROM APW.CustomersActiveStats a
	INNER JOIN APW.ControlStats c ON a.RetailerID = c.RetailerID AND ((a.ChannelType IS NULL AND c.ChannelType IS NULL) or a.ChannelType = c.ChannelType)
	--WHERE a.RetailerID IN (4138,4588)

END