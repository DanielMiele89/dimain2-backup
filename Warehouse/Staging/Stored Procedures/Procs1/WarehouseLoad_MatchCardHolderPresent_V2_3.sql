/*
Author:		Stuart Barnley
Date:		20th Oct 2013
Purpose:	To Build a MatchCardHolderPresent table in the staging schema
			then Relational schema of the Warehouse database
		
Update:		This version is being written as a temporary solution to allow data to be repopulated after the 
		SC - Added JobLog entry information
		18/02/2014 - SC - took away database references
					 SB - Also amended to stop writing data twice
				
*/
CREATE Procedure [Staging].[WarehouseLoad_MatchCardHolderPresent_V2_3]
		@LoadType bit
--Declare @LoadType bit
--Set @LoadType = 0
As


-------------------------------------------------------------------------------------------------
---------------------------------Code to Create table if needed----------------------------------
-------------------------------------------------------------------------------------------------

/*CREATE TABLE Warehouse.[Staging].[MatchCardHolderPresent_Pre] (
					MatchID INT, 
					CardHolderPresentData Char(1),
					FileID INT,
					RowNum INT)
*/
-------------------------------------------------------------------------------------------------
-------------Pull data Pre March 15th 2013 to populate Table (if full load needed)---------------
-------------------------------------------------------------------------------------------------
If @LoadType = 1
Begin

/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'WarehouseLoad_MatchCardHolderPresent_V2_3',
		TableSchemaName = 'Staging',
		TableName = 'MatchCardHolderPresent',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'R'

Truncate Table [Staging].[MatchCardHolderPresent_Pre]

Insert into [Staging].[MatchCardHolderPresent_Pre]
Select
			MatchID,CardHolderPresentData, FileID, RowNum 
		from Archive.dbo.NobleTransactionHistory with (Nolock)
		Where FileID <= 1250 and MatchID is not null
End
-------------------------------------------------------------------------------------------------
---------------------------------Code to Create table if needed----------------------------------
-------------------------------------------------------------------------------------------------
/*CREATE TABLE Warehouse.[Staging].[MatchCardHolderPresent_Post] (
					MatchID INT, 
					CardHolderPresentData Char(1),
					FileID INT,
					RowNum INT)
*/

If @LoadType <> 1
Begin

/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'WarehouseLoad_MatchCardHolderPresent_V2_3',
		TableSchemaName = 'Staging',
		TableName = 'MatchCardHolderPresent',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'A'
END

-------------------------------------------------------------------------------------------------
------------------Pull data post March 14th 2013 to populate Table-------------------------------
-------------------------------------------------------------------------------------------------
Truncate Table [Staging].[MatchCardHolderPresent]--_Post]

Declare @StartRow int, @ChunkSize tinyint, @LastFile int
Set @StartRow = 1251
Set @Chunksize = 4
Set @LastFile = (select Max(ID) from slc_report.dbo.NobleFiles)
While @StartRow <= @LastFile 
Begin
	Insert into [Staging].[MatchCardHolderPresent]--_Post]
	Select
			MatchID,CardHolderPresentData, FileID, RowNum 
	from Archive.dbo.NobleTransactionHistory with (Nolock)
	Where FileID Between @StartRow and @StartRow+4
				and MatchID is not null

	Set @StartRow = @StartRow+5
End
DECLARE	@RowCount BIGINT
SET @RowCount = (SELECT COUNT(*) FROM Staging.MatchCardHolderPresent)--_Post)


-------------------------------------------------------------------------------------------------
------------------------------Reload MatchCardHolderPresent--------------------------------------
-------------------------------------------------------------------------------------------------

--Truncate Table [Staging].[MatchCardHolderPresent]

Insert into [Staging].[MatchCardHolderPresent]
Select * from [Staging].[MatchCardHolderPresent_Pre]

--Insert into [Staging].[MatchCardHolderPresent]
--Select * from [Staging].[MatchCardHolderPresent_Post]
-------------------------------------------------------------------------------------------------
----------------------Truncate Reload [MatchCardHolderPresent_Post]------------------------------
-------------------------------------------------------------------------------------------------

Truncate Table [Staging].[MatchCardHolderPresent_Post]



/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'WarehouseLoad_MatchCardHolderPresent_V2_3' and
		TableSchemaName = 'Staging' and
		TableName = 'MatchCardHolderPresent' and
		--AppendReload = 'A' and
		EndDate is null



/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  staging.JobLog_Temp
Set		TableRowCount = (CASE	WHEN @LoadType = 0 THEN @RowCount
					ELSE (Select COUNT(*) from Staging.MatchCardHolderPresent)
				END)
where	StoredProcedureName = 'WarehouseLoad_MatchCardHolderPresent_V2_3' and
		TableSchemaName = 'Staging' and
		TableName = 'MatchCardHolderPresent' and
		TableRowCount is null


Insert into staging.JobLog
select [StoredProcedureName],
	[TableSchemaName],
	[TableName],
	[StartDate],
	[EndDate],
	[TableRowCount],
	[AppendReload]
from staging.JobLog_Temp
Truncate table staging.JobLog_Temp
