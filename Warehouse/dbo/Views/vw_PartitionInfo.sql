--USE WAREHOUSE_dev
--SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

CREATE VIEW dbo.vw_PartitionInfo AS
SELECT 
	TableName = t.[name],
	PartitionScheme = ps.[name],
	PartitionFunction = pf.[name],
	[range_type] = case when pf.boundary_value_on_right=1 then 'RIGHT' else 'LEFT' end,
	p.partition_number,
	[boundary] = prv.[value],
	p.[rows],
	x.[Size_in_MB], 
	x.DataSpaceName,
	x.dbf_Name,
	x.fg_name,
	x.physical_name
FROM sys.tables t
INNER join sys.indexes i on t.object_id = i.object_id
INNER join sys.partition_schemes ps on i.data_space_id = ps.data_space_id
INNER join sys.partition_functions pf on ps.function_id = pf.function_id
INNER join sys.partitions p on i.object_id = p.object_id and i.index_id = p.index_id
INNER join sys.partition_range_values prv on pf.function_id = prv.function_id and p.partition_number = prv.boundary_id
cross APPLY (
	SELECT 
		DataSpaceName = ds.[name], 
		dbf_Name = sdf.[name], 
		fg_name = fg.[name],
		sdf.physical_name, 
		[Size_in_MB] = sdf.size/128  
	FROM sys.allocation_units au
	INNER JOIN sys.data_spaces ds
		ON ds.data_space_id = au.data_space_id
	INNER JOIN sys.database_files sdf 
		ON sdf.data_space_id = au.data_space_id
	INNER JOIN sys.filegroups fg ON fg.data_space_id = sdf.data_space_id

	WHERE (au.type IN (1, 3) AND au.container_id = p.hobt_id) 
		OR 
		(au.type = 2 AND au.container_id = p.[partition_id])
) x
WHERE i.index_id < 2  --So we're only looking at a clustered index or heap, which the table is partitioned on
--ORDER BY p.partition_number