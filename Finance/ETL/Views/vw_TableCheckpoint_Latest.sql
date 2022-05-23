CREATE VIEW ETL.vw_TableCheckpoint_Latest
AS
	SELECT 
		x.CheckpointValue1
		, x.CheckpointValue2
		, x.CheckpointTypeID
		, x.CheckpointDateTime
		, tct.StoredProcedureName
	FROM (
		SELECT 
			*
			, ROW_NUMBER() OVER (PARTITION BY CheckpointTypeID ORDER BY CheckpointValue1 DESC, CheckpointValue2 DESC) rw
		FROM ETL.TableCheckpoint
	) x
	JOIN ETL.TableCheckpointType tct
		ON x.CheckpointTypeID = tct.CheckpointTypeID
	WHERE rw = 1
