CREATE VIEW [dbo].[vw_PartitionInfo_Transactions]
AS
	SELECT
		*
	FROM dbo.PartitionInfo
	WHERE object_id = OBJECT_ID('dbo.Transactions')

