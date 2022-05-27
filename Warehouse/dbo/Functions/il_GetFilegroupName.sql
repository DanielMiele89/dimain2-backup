
CREATE FUNCTION [dbo].[il_GetFilegroupName]
	(@TableName VARCHAR(100), @PartitionID INT)

RETURNS TABLE AS RETURN (

	SELECT x.*
	FROM sys.tables t
	CROSS APPLY (
		SELECT fg.name AS [filegroup_name], i.name AS index_name, p.data_compression_desc
		FROM sys.indexes i 
		INNER JOIN sys.partitions p 
			ON i.object_id=p.object_id 
			AND i.index_id=p.index_id
		LEFT OUTER JOIN sys.partition_schemes ps 
			ON i.data_space_id=ps.data_space_id
		LEFT OUTER JOIN sys.destination_data_spaces dds 
			ON ps.data_space_id=dds.partition_scheme_id 
			AND p.partition_number=dds.destination_id
		INNER JOIN sys.filegroups fg 
			ON COALESCE(dds.data_space_id, i.data_space_id)=fg.data_space_id
		WHERE t.object_id = i.object_id 
			AND p.partition_number = @PartitionID
	) x
	WHERE t.name = @TableName

)

