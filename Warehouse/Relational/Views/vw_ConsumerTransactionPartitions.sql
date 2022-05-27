CREATE VIEW Relational.vw_ConsumerTransactionPartitions
AS
SELECT
		OBJECT_SCHEMA_NAME(pstats.object_id) AS SchemaName
		,OBJECT_NAME(pstats.object_id) AS TableName
		,ps.name AS PartitionSchemeName
		,ds.name AS PartitionFilegroupName
		,pf.name AS PartitionFunctionName
		,prv.value AS PartitionBoundaryValue
		,c.name AS PartitionKey
		,CASE 
			WHEN pf.boundary_value_on_right = 0 
				THEN 
					ISNULL(
							DATEADD(DAY, 1, LAG(prv.value) OVER(PARTITION BY pstats.object_id ORDER BY pstats.object_id, pstats.partition_number))
						, '0001-01-01'
					)
				ELSE ISNULL(prv.value, '0001-01-01')
			END AS StartDate
		,CASE 
			WHEN pf.boundary_value_on_right = 0 
				THEN ISNULL(prv.value, '9999-12-31')
				ELSE ISNULL(
							DATEADD(DAY, -1, LEAD(prv.value) OVER(PARTITION BY pstats.object_id ORDER BY pstats.object_id, pstats.partition_number))
						, '9999-12-31'
					)
			END AS EndDate	
		,pstats.partition_number AS PartitionNumber
	--INTO #PartitionDetails
	FROM sys.dm_db_partition_stats AS pstats
	INNER JOIN sys.partitions AS p ON pstats.partition_id = p.partition_id
	INNER JOIN sys.destination_data_spaces AS dds ON pstats.partition_number = dds.destination_id
	INNER JOIN sys.data_spaces AS ds ON dds.data_space_id = ds.data_space_id
	INNER JOIN sys.partition_schemes AS ps ON dds.partition_scheme_id = ps.data_space_id
	INNER JOIN sys.partition_functions AS pf ON ps.function_id = pf.function_id
	INNER JOIN sys.indexes AS i ON pstats.object_id = i.object_id AND pstats.index_id = i.index_id AND dds.partition_scheme_id = i.data_space_id AND i.type <= 1 /* Heap or Clustered Index */
	INNER JOIN sys.index_columns AS ic ON i.index_id = ic.index_id AND i.object_id = ic.object_id AND ic.partition_ordinal > 0
	INNER JOIN sys.columns AS c ON pstats.object_id = c.object_id AND ic.column_id = c.column_id
	OUTER APPLY (
		SELECT
			CAST(prv.value AS DATE)
		FROM sys.partition_range_values AS prv 
		WHERE pf.function_id = prv.function_id AND pstats.partition_number = (CASE pf.boundary_value_on_right WHEN 0 THEN prv.boundary_id ELSE (prv.boundary_id+1) END)
		) prv(value)
	WHERE pstats.object_id = OBJECT_ID('Relational.ConsumerTransaction')