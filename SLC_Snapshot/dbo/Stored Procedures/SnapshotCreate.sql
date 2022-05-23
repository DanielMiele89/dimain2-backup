-- =============================================
-- Author:		Chris Morris
-- Create date: 20180622
-- Description:	Create the snapshot of the subscriber database, 
-- dropping it first if necessary
-- Changed 20210325 added new filegroup SLC_REPL_FastIndexes
-- =============================================
create PROCEDURE [dbo].[SnapshotCreate] 

AS
BEGIN

	SET NOCOUNT ON;

	IF EXISTS(SELECT 1 FROM sys.databases WHERE name = 'SLC_Snapshot')
	BEGIN
		DROP DATABASE SLC_Snapshot
	END

	CHECKPOINT

	CREATE DATABASE SLC_Snapshot ON 
		(NAME = SLC_REPL, FILENAME = 'E:\MSSQL\Snapshots\SLC_Snapshot.ss'),
		(NAME = SLC_REPL_Indexes, FILENAME = 'E:\MSSQL\Snapshots\SLC_REPL_Indexes.ss')
	AS SNAPSHOT OF SLC_REPL;  

END

RETURN 0

