CREATE PROC [ETL].[IronOffer_Load_OLD]
		@RunID BIGINT = NULL,
		@RowCnt INT = -1 OUTPUT
AS 
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE @RunDateTime DATETIME2 = GETDATE(),
			@StoredProcName VARCHAR(100) = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

	IF OBJECT_ID('tempdb..#IronOffer_Staging') IS NOT NULL   
		DROP TABLE #IronOffer_Staging;
	
	DECLARE @MergeCounts TABLE(ChangeType VARCHAR(20));

	SELECT
		  io.id				AS IronOfferID
		, io.[name]			AS IronOfferName
		, startdate
		, io.EndDate
		, io.PartnerID
		, ioc.ClubID		AS PublisherID
		, @RunDateTime			AS CreatedDateTime
		, @RunDateTime			AS UpdatedDateTime
	INTO #IronOffer_Staging 
	FROM SLC_Report..IronOffer io
	JOIN (
		SELECT IronOfferID, Max(ClubID)	AS ClubID
		FROM slc_report.dbo.IronOfferClub
		GROUP BY IronOfferID
	) ioc
		ON io.id = ioc.IronOfferID

	UNION ALL

	SELECT
		-1
		, 'NOT APPLICABLE'
		, '1900-01-01'
		, '9999-01-01'
		, -1
		, -1
		, @RunDateTime
		, @RunDateTime

	BEGIN TRAN

		MERGE dbo.IronOffer AS TGT 
			USING #IronOffer_Staging AS SRC   
				ON TGT.IronOfferID = SRC.IronOfferID 
		WHEN MATCHED AND
					EXISTS (SELECT tgt.* EXCEPT SELECT src.*)
			THEN   
				UPDATE SET     
						TGT.IronOfferName	= SRC.IronOfferName,     
						TGT.startdate		= SRC.startdate,     
						TGT.EndDate			= SRC.EndDate,
						TGT.PartnerID		= SRC.PartnerID,
						TGT.PublisherID		= SRC.PublisherID,
						TGT.UpdatedDateTime = SRC.[UpdatedDateTime]
		WHEN NOT MATCHED THEN    
			INSERT (IronOfferID, IronOfferName, startdate, EndDate, PartnerID, PublisherID, CreatedDateTime, UpdatedDateTime)   
			VALUES (SRC.IronOfferID, SRC.IronOfferName, SRC.startdate, SRC.EndDate, SRC.PartnerID, SRC.PublisherID, SRC.CreatedDateTime, src.UpdatedDateTime) 
		OUTPUT $Action INTO @MergeCounts;
		SET @RowCnt = @@ROWCOUNT;


		;WITH MergeChangeAggregations AS (
			SELECT ChangeType, COUNT(*) AS CountPerChangeType
			FROM @MergeCounts
			GROUP BY ChangeType
		)
		INSERT INTO dbo.Audit_MergeLogging
		SELECT
				@RunID
				,@RunDateTime
				,@StoredProcName
				,InsertedRows = ISNULL((SELECT CountPerChangeType FROM MergeChangeAggregations WHERE ChangeType = 'INSERT'),0)
				,UpdatedRows = ISNULL((SELECT CountPerChangeType FROM MergeChangeAggregations WHERE ChangeType = 'UPDATE'),0)
				,DeletedRows = ISNULL((SELECT CountPerChangeType FROM MergeChangeAggregations WHERE ChangeType = 'DELETE'),0)
	COMMIT TRAN

END


