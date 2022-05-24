
/*
-- (Mostly) replaces this bunch of stored procedures:
EXEC [WHB].[Redemptions_ElectronicRedemptions_And_Stock_Populate]
EXEC [WHB].[Redemptions_Card_Redemptions_Populate]

*/

CREATE PROCEDURE [WHB].[__Redemptions_Weekdays_Archived] 

AS 

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @msg VARCHAR(200), @RowsAffected INT



-------------------------------------------------------------------------------
--EXEC WHB.Redemptions_ElectronicRedemptions_And_Stock_Populate ###############
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'Redemptions_ElectronicRedemptions_And_Stock_Populate', 'Starting'
EXEC WHB.Redemptions_ElectronicRedemptions_And_Stock_Populate
EXEC Monitor.ProcessLog_Insert 'WHB', 'Redemptions_ElectronicRedemptions_And_Stock_Populate', 'Finished'



-------------------------------------------------------------------------------
--EXEC WHB.Redemptions_Card_Redemptions_Populate ##############################
-------------------------------------------------------------------------------

EXEC Monitor.ProcessLog_Insert 'WHB', 'Redemptions_Card_Redemptions_Populate', 'Starting'
EXEC WHB.Redemptions_Card_Redemptions_Populate
EXEC Monitor.ProcessLog_Insert 'WHB', 'Redemptions_Card_Redemptions_Populate', 'Finished'



RETURN 0