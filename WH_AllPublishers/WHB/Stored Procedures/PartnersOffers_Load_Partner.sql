
CREATE PROCEDURE [WHB].[PartnersOffers_Load_Partner]
AS
BEGIN

 SET XACT_ABORT ON;
 
	/*******************************************************************************************************************************************
		1.	Declare variables
	*******************************************************************************************************************************************/

		DECLARE @MergeCounts TABLE(MergeAction VARCHAR(20))
		
		DECLARE	@Inserted INT
			,	@Updated INT
			,	@Deleted INT 

	/*******************************************************************************************************************************************
		2.	Load to [Derived].[Partner]
	*******************************************************************************************************************************************/
	
		MERGE INTO [Derived].[Partner] AS TGT
		USING [Inbound].[Partner] AS SRC
			ON TGT.[PartnerID] = SRC.[PartnerID]

		WHEN MATCHED THEN 
		UPDATE SET	TGT.[RetailerID]				=	SRC.[RetailerID]
				,	TGT.[RetailerGUID]				=	SRC.[RetailerGUID]
				,	TGT.[RetailerName]				=	SRC.[RetailerName]
				,	TGT.[RetailerRegisteredName]	=	SRC.[RetailerRegisteredName]
				,	TGT.[PartnerID]					=	SRC.[PartnerID]
				,	TGT.[PartnerName]				=	SRC.[PartnerName]
				,	TGT.[PartnerRegisteredName]		=	SRC.[PartnerRegisteredName]
				,	TGT.[AccountManager]			=	SRC.[AccountManager]
				,	TGT.[Status]					=	SRC.[Status]
				,	TGT.[ShowMaps]					=	SRC.[ShowMaps]
				,	TGT.[ModifiedDate]				=	CASE
															WHEN CHECKSUM(TGT.[RetailerID], TGT.[RetailerGUID], TGT.[RetailerName], TGT.[RetailerRegisteredName], TGT.[PartnerID], TGT.[PartnerName], TGT.[PartnerRegisteredName], TGT.[AccountManager], TGT.[Status], TGT.[ShowMaps]) != CHECKSUM(SRC.[RetailerID], SRC.[RetailerGUID], SRC.[RetailerName], SRC.[RetailerRegisteredName], SRC.[PartnerID], SRC.[PartnerName], SRC.[PartnerRegisteredName], SRC.[AccountManager], SRC.[Status], SRC.[ShowMaps]) THEN GETDATE()
															ELSE TGT.[ModifiedDate]
														END

		WHEN NOT MATCHED THEN
		INSERT (	[RetailerID], [RetailerGUID], [RetailerName], [RetailerRegisteredName], [PartnerID], [PartnerName], [PartnerRegisteredName], [AccountManager], [Status], [ShowMaps], [BrandID], [BrandName], [AddedDate], [ModifiedDate])
		VALUES (	[RetailerID], [RetailerGUID], [RetailerName], [RetailerRegisteredName], [PartnerID], [PartnerName], [PartnerRegisteredName], [AccountManager], [Status], [ShowMaps], 944, 'MID Not Yet Branded', GETDATE(), GETDATE())
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
		SELECT	COALESCE(OBJECT_NAME(@@PROCID), 'PartnersOffers_Load_Offer - ' + SYSTEM_USER)
			,	GETDATE()
			,	@Inserted
			,	@Updated
			,	@Deleted

		DELETE FROM @MergeCounts
		
END