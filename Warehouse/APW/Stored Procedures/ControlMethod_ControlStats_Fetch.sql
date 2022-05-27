-- =============================================
-- Author:		JEA
-- Create date: 06/06/2016
-- Description:	Fetches Control Stats
-- =============================================
CREATE PROCEDURE APW.ControlMethod_ControlStats_Fetch 
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT MonthDate
		, RetailerID
		, RR
		, SPS
		, ATV
		, ATF
		, ChannelType
	FROM APW.ControlStats
	ORDER BY RetailerID, ChannelType

END
