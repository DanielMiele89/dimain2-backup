/*
-- Replaces this bunch of 4 stored procedures:
EXEC Selections.CampaignCode_Selections_ShopperSegment_ALS_PreSelections 1, @EmailDate 
EXEC Warehouse.Selections.SKY001_PreSelection_sProc
EXEC Selections.CampaignSetup_Selection_Loop_POS 1, @EmailDate
EXEC Selections.CampaignSetup_Selection_Loop_DD 1, @EmailDate

*/
CREATE PROCEDURE [WHB].MyRewardsCampaignSelections 

AS 

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
DECLARE @msg VARCHAR(200), @RowsAffected INT



-------------------------------------------------------------------------------
--EXEC Selections.CampaignCode_Selections_ShopperSegment_ALS_PreSelections ####
-------------------------------------------------------------------------------
DECLARE @EmailDate DATE = GETDATE()

EXEC Monitor.ProcessLog_Insert 'WHB', 'CampaignCode_Selections_ShopperSegment_ALS_PreSelections', 'Starting'
EXEC Selections.CampaignCode_Selections_ShopperSegment_ALS_PreSelections 1, @EmailDate
EXEC Monitor.ProcessLog_Insert 'WHB', 'CampaignCode_Selections_ShopperSegment_ALS_PreSelections', 'Finished'



-------------------------------------------------------------------------------
--EXEC Selections.SKY001_PreSelection_sProc #########################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'SKY001_PreSelection_sProc', 'Starting'
EXEC Selections.SKY001_PreSelection_sProc
EXEC Monitor.ProcessLog_Insert 'WHB', 'SKY001_PreSelection_sProc', 'Finished'



-------------------------------------------------------------------------------
--EXEC Selections.CampaignSetup_Selection_Loop_POS ############################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'CampaignSetup_Selection_Loop_POS', 'Starting'
EXEC Selections.CampaignSetup_Selection_Loop_POS 1, @EmailDate
EXEC Monitor.ProcessLog_Insert 'WHB', 'CampaignSetup_Selection_Loop_POS', 'Finished'



-------------------------------------------------------------------------------
--EXEC Selections.CampaignSetup_Selection_Loop_DD #############################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'CampaignSetup_Selection_Loop_DD', 'Starting'
EXEC Selections.CampaignSetup_Selection_Loop_DD 1, @EmailDate
EXEC Monitor.ProcessLog_Insert 'WHB', 'CampaignSetup_Selection_Loop_DD', 'Finished'



RETURN 0


