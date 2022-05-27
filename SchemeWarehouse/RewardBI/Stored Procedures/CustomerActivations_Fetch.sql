
-- =============================================
-- Author:		JEA
-- Create date: 10/09/2014
-- Description:	Fetches activation info for the Reward BI Database
-- =============================================
CREATE PROCEDURE [RewardBI].[CustomerActivations_Fetch] 
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT FanID
		, ActivationStatusID
		, CAST(CASE WHEN ActivationStatusID = 1 THEN 1 ELSE -1 END AS INT) AS EventValue
		, StatusDate AS EventDate
	FROM RewardBI.CustomerActivationLog

END

