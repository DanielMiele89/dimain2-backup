



CREATE PROC [WHB].[__nFI_WarehouseConsumer_Load]
AS

 SET XACT_ABORT ON;

 DECLARE @MergeCounts TABLE(MergeAction VARCHAR(20))

 MERGE INTO [WH_AllPublishers].[dbo].[Consumer] AS TGT
 USING [WH_AllPublishers].[Inbound].[nFI_Customer] AS SRC
	ON TGT.SourceTypeID = 4
	AND TGT.SourceID = SRC.SourceUID
 WHEN MATCHED THEN 
	UPDATE SET
	 TGT.[FanID]				= SRC.[FanID]
      ,TGT.[SourceID]			= SRC.[SourceUID]
      ,TGT.[ClubID]				= SRC.[ClubID]
      ,TGT.[Region]				= SRC.[Region]
      ,TGT.[PostalSector]		= SRC.[PostalSector]
      ,TGT.[Gender]				= SRC.[Gender]
      ,TGT.[AgeCurrent]			= SRC.[AgeCurrent]
      ,TGT.[RegistrationDate]   = SRC.[RegistrationDate]
	,TGT.[SourceTypeID]		= 4
	,TGT.[UpdatedDateTime]	= GETDATE()
  WHEN NOT MATCHED THEN
	INSERT ([FanID], [ClubID], [PublisherID], [Region], [PostalSector], [Gender], [AgeCurrent], [RegistrationDate], [SourceID], [SourceTypeID], [CreatedDateTime], [UpdatedDateTime])
	VALUES ([FanID], [ClubID], [ClubID], [Region], [PostalSector], [Gender], [AgeCurrent], [RegistrationDate], [SourceUID], 4, GETDATE(), GETDATE())
  OUTPUT $action INTO @MergeCounts	
	;
	
	DECLARE @Inserted INT, @Updated INT, @Deleted INT 
	;WITH MergeActions AS(
		SELECT MergeAction,COUNT(*) As Total FROM @MergeCounts
		GROUP BY MergeAction
	)
	SELECT
		@Inserted = (SELECT COALESCE(Total,0) FROM MergeActions WHERE MergeActions.MergeAction = 'INSERT')
		,@Updated = (SELECT COALESCE(Total,0) FROM MergeActions WHERE MergeActions.MergeAction = 'UPDATE')
		,@Deleted = (SELECT COALESCE(Total,0) FROM MergeActions WHERE MergeActions.MergeAction = 'DELETE')

	INSERT INTO dbo.WarehouseLoadAudit(ProcName,RunDateTime,RowsInserted,RowsUpdated,RowsDeleted)
	SELECT OBJECT_NAME(@@PROCID),GETDATE(), @Inserted,@Updated,@Deleted

