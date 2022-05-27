
CREATE PROCEDURE [WHB].[PartnersOffers_Load_Publisher]
AS
BEGIN

		SET NOCOUNT ON

		SET XACT_ABORT ON;
 
	/*******************************************************************************************************************************************
		1.	Declare variables
	*******************************************************************************************************************************************/

		DECLARE @MergeCounts TABLE(MergeAction VARCHAR(20))
		
		DECLARE	@Inserted INT
			,	@Updated INT
			,	@Deleted INT

	/*******************************************************************************************************************************************
		2.	Load to [Derived].[Publisher]
	*******************************************************************************************************************************************/
	
		MERGE INTO [Derived].[Publisher] AS TGT
		USING [Inbound].[Publisher] AS SRC
			ON TGT.[PublisherID] = SRC.[PublisherID]

		WHEN MATCHED THEN 
		UPDATE SET	TGT.[PublisherName]			=	SRC.[PublisherName]
				,	TGT.[PublisherNickname]		=	SRC.[PublisherNickname]
				,	TGT.[PublisherAbbreviation]	=	SRC.[PublisherAbbreviation]
				,	TGT.[PublisherType]			=	SRC.[PublisherType]
				,	TGT.[LiveStatus]			=	SRC.[LiveStatus]
				,	TGT.[ModifiedDate]				=	CASE
															WHEN CHECKSUM(TGT.[PublisherName], TGT.[PublisherNickname], TGT.[PublisherAbbreviation], TGT.[PublisherType], TGT.[LiveStatus]) != CHECKSUM(SRC.[PublisherName], SRC.[PublisherNickname], SRC.[PublisherAbbreviation], SRC.[PublisherType], SRC.[LiveStatus]) THEN GETDATE()
															ELSE TGT.[ModifiedDate]
														END

		WHEN NOT MATCHED THEN
		INSERT (	[PublisherID], [PublisherName], [PublisherNickname], [PublisherAbbreviation], [PublisherType], [LiveStatus], [AddedDate], [ModifiedDate])
		VALUES (	[PublisherID], [PublisherName], [PublisherNickname], [PublisherAbbreviation], [PublisherType], [LiveStatus], GETDATE(), GETDATE())
		OUTPUT $action
		INTO @MergeCounts;
	
		;WITH
		MergeActions AS (	SELECT	MergeAction
								,	COUNT(*) As Total
							FROM @MergeCounts
							GROUP BY MergeAction)
		SELECT	@Inserted = (SELECT COALESCE(Total,0) FROM MergeActions WHERE MergeActions.MergeAction = 'INSERT')
			,	@Updated = (SELECT COALESCE(Total,0) FROM MergeActions WHERE MergeActions.MergeAction = 'UPDATE')
			,	@Deleted = (SELECT COALESCE(Total,0) FROM MergeActions WHERE MergeActions.MergeAction = 'DELETE')

		INSERT INTO [dbo].[WarehouseLoadAudit] (ProcName
											,	RunDateTime
											,	RowsInserted
											,	RowsUpdated
											,	RowsDeleted)
		SELECT	COALESCE(OBJECT_NAME(@@PROCID), 'PartnersOffers_Load_Publisher - ' + SYSTEM_USER)
			,	GETDATE()
			,	@Inserted
			,	@Updated
			,	@Deleted

		DELETE FROM @MergeCounts
		
END