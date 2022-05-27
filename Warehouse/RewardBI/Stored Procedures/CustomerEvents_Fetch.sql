-- =============================================
-- Author:		JEA
-- Create date: 09/09/2014
-- Description:	Retrieves cross-scheme customer events
-- for Reward BI
-- =============================================
CREATE PROCEDURE RewardBI.CustomerEvents_Fetch 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT FanID
		, CAST(1 AS TINYINT) AS SchemeID --Cashback Plus
		, CAST(1 AS TINYINT) AS PublisherID --RBS
		, CAST(1 AS TINYINT) AS CustomerEventTypeID --Activation
		, ActivatedDate AS EventDate
		, CAST(1 AS INT) AS EventValue
	FROM MI.CustomerActiveStatus

	UNION ALL

	SELECT FanID
		, CAST(1 AS TINYINT) AS SchemeID --Cashback Plus
		, CAST(1 AS TINYINT) AS PublisherID --RBS
		, CAST(2 AS TINYINT) AS CustomerEventTypeID --Opt Out
		, OptedOutDate AS EventDate
		, CAST(-1 AS INT) AS EventValue 
	FROM MI.CustomerActiveStatus
	WHERE OptedOutDate IS NOT NULL

	UNION ALL

	SELECT FanID
		, CAST(1 AS TINYINT) AS SchemeID --Cashback Plus
		, CAST(1 AS TINYINT) AS PublisherID --RBS
		, CAST(3 AS TINYINT) AS CustomerEventTypeID --Opt Out
		, DeactivatedDate AS EventDate
		, CAST(-1 AS INT) AS EventValue 
	FROM MI.CustomerActiveStatus
	WHERE DeactivatedDate IS NOT NULL AND OptedOutDate IS NULL

END
