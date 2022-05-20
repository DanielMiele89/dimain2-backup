/*
Index maintenance for the subscriber database.
Fillfactor is set at 80%.
If page splits have started (fragmentation is >= 1%) then rebuild 
	- shuffles data around until pages have 80% free space again.
Otherwise update stats.
#1 20180620: 01:37:58
#2 20180626: 02:00:44
*/
create PROCEDURE [dbo].[IndexMaintenance_SLC_REPL]

AS

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE 
	@time DATETIME,
	@msg VARCHAR(2048),
	@SSMS BIT,
	@weekday VARCHAR(10) = DATENAME(weekday, GETDATE());

EXEC dbo.oo_TimerMessageV2 'Start process Index Maintenance', @time OUTPUT, @SSMS OUTPUT;

-- drop the snapshot, don't want it recording these changes (does it?)
IF EXISTS(SELECT 1 FROM sys.databases WHERE name = 'SLC_Snapshot')
BEGIN
	DROP DATABASE SLC_Snapshot
	EXEC dbo.oo_TimerMessageV2 'Dropped snapshot', @time OUTPUT, @SSMS OUTPUT;
END

-- Ensure any changes are already written to disk
CHECKPOINT;


-- Special requests ------------------------------------
-- If the indexing step takes too long, then change this to DATA_COMPRESSION = ROW
-- space savings will be less but it will run quite a bit quicker.
IF NOT EXISTS (
	SELECT 1 FROM sys.indexes idx 
	WHERE idx.object_id = OBJECT_ID(N'SLC_REPL.dbo.IronOfferMember') 
		AND idx.Name = 'sn_Stuff01' 
)
BEGIN
	CREATE INDEX [sn_Stuff01] ON SLC_REPL.dbo.IronOfferMember ([ImportDate], [CompositeID]) INCLUDE ([IronOfferID], [StartDate], [EndDate], [IsControl]) WITH (DATA_COMPRESSION = PAGE, SORT_IN_TEMPDB = ON, FILLFACTOR = 80)  ON [SLC_REPL_FastIndexes]
END

IF NOT EXISTS (
	SELECT 1 FROM sys.indexes idx 
	WHERE idx.object_id = OBJECT_ID(N'SLC_REPL.dbo.EmailActivity') 
		AND idx.Name = 'ix_Stuff' 
)
BEGIN
	CREATE INDEX ix_Stuff ON EmailActivity (FanID) INCLUDE (EmailCampaignID, OpenDate) WITH (DATA_COMPRESSION = PAGE, SORT_IN_TEMPDB = ON, FILLFACTOR = 70)  ON [SLC_REPL_FastIndexes]
END

IF NOT EXISTS (
	SELECT 1 FROM sys.indexes idx 
	WHERE idx.object_id = OBJECT_ID(N'SLC_REPL.dbo.EmailActivity') 
		AND idx.Name = 'ix_Stuff2' 
)
BEGIN
	CREATE INDEX ix_Stuff2 ON EmailActivity (EmailCampaignID, FanID) INCLUDE (OpenDate) WITH (DATA_COMPRESSION = PAGE, SORT_IN_TEMPDB = ON, FILLFACTOR = 70)  ON [SLC_REPL_FastIndexes]
END

-- Special requests ------------------------------------



RETURN 0



