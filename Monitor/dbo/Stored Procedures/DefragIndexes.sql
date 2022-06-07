/*******************************************************************************
Generic Index Defragmentation Procedure
********************************************************************************
Table definition for storing the IndexFragmentation data
********************************************************************************
create table monitor.dbo.IndexFragmentation (
	id int identity(1,1) primary key,
	DateCollected datetime not null,
	DateStarted datetime null,
	DateFinished datetime null,
	databaseid smallint not null,
	databasename sysname not null,
	schemaid int not null,
	schemaname sysname not null,
	Tableid int not null,
	Tablename sysname not null,
	indexid int not null,
	indexname sysname null,
	partition_number int not null,
	index_type_desc nvarchar(60) not null,
	alloc_unit_type_desc nvarchar(60) not null,
	index_depth tinyint not null,
	index_level tinyint not null,
	avg_fragmentation_in_percent float not null,
	fragment_count bigint null, 
	avg_fragment_size_in_pages float null,
	page_count bigint not null,
	allowpagelocks bit not null,
	ActionNote varchar(256) null,
	Usage bigint null,
	LastAccess datetime null
);
********************************************************************************
Optimisations needed to this process:
	Index on the IndexFragmentation table
		It's got a PK but only on the ID field. Need to run the data collection before indexing can be properly looked at.
********************************************************************************
SP control using @stopAfter
	-1 for data collection only
	0 for defrag until complete
	>= 1 number of minutes to spend defragmenting
*******************************************************************************/

CREATE procedure [dbo].[DefragIndexes]
	@DBName sysname,
	@DefragFloor float = 10,
	@RebuildFloor float = 30,
	@stopAfter int = -1, --Only collect the data
	@indexSizeLimit int = 1000
as

RETURN -- Don't use this. REORGANISE is hopeless.

declare @dbid tinyint, @rundate datetime;
declare @thisid int, @tabname nvarchar(512), @idxname nvarchar(128), @idxtype nvarchar(60), @partid int, @avgFrag float, @pagecount int, @allowpagelocks bit;
declare @sqlcmd nvarchar(max), @errMsg varchar(256);

set nocount on;

--Get the ID of the given database
set @dbid = DB_ID(@DBName);
--Record the current time to use throughout
set @rundate = getdate();

--Make a note
If @stopAfter >= 0 set @errMsg = 'Beginning index defragmentation process for database ' + CAST(@DBName as varchar) + '.'
else set @errMsg = 'Collecting index fragmentation data for database ' + CAST(@DBName as varchar) + '.';
raiserror (@errMsg, 1, 1) with nowait;

--Check if the stats have been collected in the last 23 hours or not
if (select isnull(datediff(hh, (select max(DateCollected) from  monitor.dbo.IndexFragmentation where databasename = @DBName), @rundate),12)) >= 11
begin

	set @sqlcmd = 'select ''' + CONVERT(varchar, @rundate, 120) + ''' as DateCollected,
		i.database_id as databaseid, ''' + @DBName + ''' as databasename,
		o.schema_id as schemaid, s.name as schemaname,
		i.Object_id as tableid, o.name as tablename,
		i.index_id as indexid, x.name as indexname,
		partition_number, index_type_desc, alloc_unit_type_desc, index_depth, index_level,
		avg_fragmentation_in_percent, fragment_count, 
		avg_fragment_size_in_pages, page_count, allow_page_locks,
		COALESCE(u.user_seeks, 0) + COALESCE(u.user_scans, 0) + COALESCE(u.user_lookups, 0) as Usage,
		(SELECT  MAX(LastAccess) 
		FROM (VALUES (u.last_user_seek),
				(u.last_user_scan),
				(u.last_user_lookup)
			) AS value(LastAccess)
		) AS LastAccess
	from sys.dm_db_index_physical_stats(' + cast(@dbid as varchar) + ', NULL, NULL, NULL, NULL) i
	inner join ' + @DBName + '.sys.indexes x on i.object_id = x.object_id and i.index_id = x.index_id
	inner join ' + @DBName + '.sys.objects o on i.object_id = o.object_id
	inner join ' + @DBName + '.sys.schemas s on o.schema_id = s.schema_id
	left join sys.dm_db_index_usage_stats u on i.database_id = u.database_id and i.object_id = u.object_id and i.index_id = u.index_id
	where o.type = ''U'';';

	insert into monitor.dbo.IndexFragmentation (DateCollected,
		databaseid, databasename, schemaid, schemaname, Tableid, tablename, indexid, indexname,
		partition_number, index_type_desc, alloc_unit_type_desc, index_depth, index_level,
		avg_fragmentation_in_percent, fragment_count, 
		avg_fragment_size_in_pages, page_count, allowpagelocks,
		Usage, LastAccess)
	exec sp_sqlexec @sqlcmd;
/*
	select @rundate as DateCollected,
		database_id, i.Object_id, index_id, partition_number,
		index_type_desc, alloc_unit_type_desc, index_depth, index_level,
		avg_fragmentation_in_percent, fragment_count, 
		avg_fragment_size_in_pages, page_count
	from sys.dm_db_index_physical_stats(@dbid, NULL, NULL, NULL, NULL) i
	inner join sys.objects o on i.object_id = o.object_id
	where o.type = 'U'; --Only deal with user tables
*/
	--Make a note
	raiserror ('Collected index fragmentation data', 1, 1) with nowait;
end
else raiserror ('Skipping index data collection. Already completed within the last 24 hours.', 1, 1) with nowait;

--Only if actual defragmentation is asked for
If @stopAfter >= 0
begin
	--Build a cursor to step through the indexes that need defragging/rebuilding
	declare curIndexFrag cursor for
		select id, databasename + '.' + schemaname + '.' + tablename, indexname, index_type_desc, partition_number, avg_fragmentation_in_percent, page_count, allowpagelocks
		from  monitor.dbo.IndexFragmentation
		where databasename = @DBName
		and DateCollected > DATEADD(hh, -24, @rundate)
		and avg_fragmentation_in_percent > @DefragFloor
		--and page_count > @indexSizeLimit --Don't bother with small indexes
		--and indexid > 0 --Or heaps
		and DateFinished is null
		--Sort by an (almost) arbitary impact score 
		order by COALESCE((Usage * avg_fragmentation_in_percent * page_count), 0) desc, avg_fragmentation_in_percent desc;

	--Open the cursor
	open curIndexFrag;

	--Get the first entry
	FETCH FROM curIndexFrag into @thisid, @tabname, @idxname, @idxtype, @partid, @avgFrag, @pagecount, @allowpagelocks;

	--As long as the returned values are valid
	while @@FETCH_STATUS = 0 and (datediff(mi, dateadd(mi, @StopAfter, @rundate), getdate()) < 0 or @StopAfter = 0)
	begin
		--Check that we can (and should) actually defrag this
		If @idxname is null
			begin
			update monitor.dbo.IndexFragmentation set ActionNote = 'Heap alert!' where id = @thisid;
			set @sqlcmd = null
			end

		--Check that it's big enough to warrant defragmenting
		Else If @pagecount <= @indexSizeLimit
			begin
			update monitor.dbo.IndexFragmentation set ActionNote = 'Not larger than the minimum specified size of ' + cast(@indexSizeLimit as varchar) + ' pages. Not worth defragging.' where id = @thisid;
			set @sqlcmd = null
			end

		--Check that it's not just a part of a partitioned index
		Else If @avgFrag > @RebuildFloor and @partid > 1
			begin
			update monitor.dbo.IndexFragmentation set ActionNote = 'Parts of a partitioned index cannot be rebuilt online, the whole thing must be done at once. See this index, partition ID = 1.' where id = @thisid;
			set @sqlcmd = null
			end

		--If it's fragmented enough rebuild it, online if possible
		Else If @avgFrag > @RebuildFloor
			begin
			set @sqlcmd = N'alter index ' + @idxname + ' on ' + @tabname + N' rebuild'
				+ CASE WHEN @idxtype not in ('XML','SPATIAL') THEN N' with (online = on)' END + N';';
			update monitor.dbo.IndexFragmentation set ActionNote = LEFT(@sqlcmd, 256) where id = @thisid;
			end

		--Check we're not trying to defragment an index with Page locks disallowed. Rebuild instead (but add a note)
		Else If @avgFrag > @DefragFloor and @allowpagelocks = 0
			begin
			set @sqlcmd = N'alter index ' + @idxname + ' on ' + @tabname + N' rebuild'
				+ CASE WHEN @idxtype not in ('XML','SPATIAL') THEN N' with (online = on)' END + N';';
			update monitor.dbo.IndexFragmentation set ActionNote = LEFT('Cannot defragment, must rebuild. Index does not allow page locks. ' + @sqlcmd, 256) where id = @thisid;
			end

		--Otherwise just reorganise it
		Else If @avgFrag > @DefragFloor
			begin
			set @sqlcmd = N'alter index ' + @idxname + ' on ' + @tabname + N' reorganize;';
			update monitor.dbo.IndexFragmentation set ActionNote = LEFT(@sqlcmd, 256) where id = @thisid;
			end

		If @sqlcmd is not null
			begin
			--Update when it started
			update monitor.dbo.IndexFragmentation set DateStarted = GETDATE() where id = @thisid;

			--Actually run it
			--print @sqlcmd;
			exec sp_sqlexec @sqlcmd;

			--And then when it finished
			update monitor.dbo.IndexFragmentation set DateFinished = GETDATE() where id = @thisid;
			end;

		--Get the next one
		FETCH NEXT FROM curIndexFrag into @thisid, @tabname, @idxname, @idxtype, @partid, @avgFrag, @pagecount, @allowpagelocks;
	end;

	--Tidy up cursor stuff
	close curIndexFrag;
	deallocate curIndexFrag;

	if @StopAfter > 0 and datediff(mi, dateadd(mi, @StopAfter, @rundate), getdate()) < 0
		raiserror ('Exiting Index Defragmentation as the window has closed', 1, 1) with nowait;

	--Make a note
	raiserror ('Completed Index Defragmentation.', 1, 1) with nowait;
end
