


CREATE PROC [WHB].[__Visa_WarehouseConsumer_Load]
AS

 SET XACT_ABORT ON;

 DECLARE @MergeCounts TABLE(MergeAction VARCHAR(20))

 MERGE INTO [WH_AllPublishers].[dbo].[Consumer] AS TGT
 USING [WH_AllPublishers].[Inbound].[Visa_Customer] AS SRC
	ON TGT.SourceTypeID = 10
	AND TGT.SourceID = SRC.SourceUID
 WHEN MATCHED THEN 
	UPDATE SET
	 TGT.[FanID]				= SRC.[FanID]
      ,TGT.[SourceID]			= SRC.[CustomerGUID]
      ,TGT.[ClubID]				= SRC.[ClubID]
      ,TGT.[AccountType]		= SRC.[AccountType]
      ,TGT.[Title]				= SRC.[Title]
      ,TGT.[City]				= SRC.[City]
      ,TGT.[County]				= SRC.[County]
      ,TGT.[Region]				= SRC.[Region]
      ,TGT.[PostalSector]		= SRC.[PostalSector]
      ,TGT.[PostCodeDistrict]	= SRC.[PostCodeDistrict]
      ,TGT.[PostArea]			= SRC.[PostArea]
      ,TGT.[Gender]				= SRC.[Gender]
      ,TGT.[AgeCurrent]			= SRC.[AgeCurrent]
      ,TGT.[AgeCurrentBandText] = SRC.[AgeCurrentBandText]
      ,TGT.[MarketableByEmail]  = SRC.[MarketableByEmail]
      ,TGT.[MarketableByPush]   = SRC.[MarketableByPush]
      ,TGT.[CurrentlyActive]	= SRC.[CurrentlyActive]
      ,TGT.[RegistrationDate]   = SRC.[RegistrationDate]
      ,TGT.[DeactivatedDate]    = SRC.[DeactivatedDate]
	,TGT.[SourceTypeID]		= 10
	,TGT.[UpdatedDateTime]	= GETDATE()
  WHEN NOT MATCHED THEN
	INSERT ([FanID], [ClubID], [PublisherID], [AccountType], [Title], [City], [County], [Region], [PostalSector], [PostCodeDistrict], [PostArea], [Gender], [AgeCurrent], [AgeCurrentBandText], [MarketableByEmail], [MarketableByPush], [CurrentlyActive], [RegistrationDate], [DeactivatedDate], [SourceID], [SourceTypeID], [CreatedDateTime], [UpdatedDateTime])
	VALUES ([FanID], [ClubID], [ClubID],  [AccountType], [Title], [City], [County], [Region], [PostalSector], [PostCodeDistrict], [PostArea], [Gender], [AgeCurrent], [AgeCurrentBandText], [MarketableByEmail], [MarketableByPush], [CurrentlyActive], [RegistrationDate], [DeactivatedDate], [SourceUID], 10, GETDATE(), GETDATE())
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

