/*
-- Partially replaces this bunch of stored procedures:
EXEC MI.CBP_CustomerSpend_Fetch
EXEC MI.CBP_DailyMIReport_Fetch
*/
CREATE PROCEDURE [WHB].[__MyRewardsDailyMIFileTableLoad_Archived] 

AS 

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;


RETURN 0