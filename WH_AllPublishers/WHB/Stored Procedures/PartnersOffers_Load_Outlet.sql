
CREATE PROCEDURE [WHB].[PartnersOffers_Load_Outlet]
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
		2.	Load to [Derived].[Outlet]
	*******************************************************************************************************************************************/

		/***************************************************************************************************************************************
			2.1.	Load entries where [OutletID] is the [SourceID]
		***************************************************************************************************************************************/
	
			;WITH
			Inbound_Outlet_OutletID AS (	SELECT *
											FROM [Inbound].[Outlet]
											--WHERE [SourceOfferID] = 'OutletID'
											)

			MERGE INTO [Derived].[Outlet] AS TGT
			USING Inbound_Outlet_OutletID AS SRC
				ON TGT.[OutletID] = SRC.[OutletID]

			WHEN MATCHED THEN
			UPDATE SET	TGT.[PartnerID]					=	SRC.[PartnerID]
					,	TGT.[PartnerOutletReference]	=	SRC.[PartnerOutletReference]
					,	TGT.[MerchantID]				=	SRC.[MerchantID]
					,	TGT.[Status]					=	SRC.[Status]
					,	TGT.[Channel]					=	SRC.[Channel]
					,	TGT.[IsOnline]					=	SRC.[IsOnline]
					,	TGT.[Address1]					=	SRC.[Address1]
					,	TGT.[Address2]					=	SRC.[Address2]
					,	TGT.[City]						=	SRC.[City]
					,	TGT.[Postcode]					=	SRC.[Postcode]
					,	TGT.[PostalSector]				=	SRC.[PostalSector]
					,	TGT.[PostArea]					=	SRC.[PostArea]
					,	TGT.[Region]					=	SRC.[Region] 
					,	TGT.[Latitude]					=	SRC.[Latitude]
					,	TGT.[Longitude]					=	SRC.[Longitude]
					,	TGT.[ModifiedDate]				=	CASE
																WHEN CHECKSUM(TGT.[OutletID], TGT.[PartnerID], TGT.[PartnerOutletReference], TGT.[MerchantID], TGT.[Status], TGT.[Channel], TGT.[IsOnline], TGT.[Address1], TGT.[Address2], TGT.[City], TGT.[Postcode], TGT.[PostalSector], TGT.[PostArea], TGT.[Region], TGT.[Latitude], TGT.[Longitude]) != CHECKSUM(SRC.[OutletID], SRC.[PartnerID], SRC.[PartnerOutletReference], SRC.[MerchantID], SRC.[Status], SRC.[Channel], SRC.[IsOnline], SRC.[Address1], SRC.[Address2], SRC.[City], SRC.[Postcode], SRC.[PostalSector], SRC.[PostArea], SRC.[Region], SRC.[Latitude], SRC.[Longitude]) THEN GETDATE()
																ELSE TGT.[ModifiedDate]
															END

			WHEN NOT MATCHED THEN INSERT ([OutletID], [PartnerID], [PartnerOutletReference], [MerchantID], [Status], [Channel], [IsOnline], [Address1], [Address2], [City], [Postcode], [PostalSector], [PostArea], [Region], [Latitude], [Longitude], [AddedDate], [ModifiedDate])
			VALUES ([OutletID], [PartnerID], [PartnerOutletReference], [MerchantID], [Status], [Channel], [IsOnline], [Address1], [Address2], [City], [Postcode], [PostalSector], [PostArea], [Region], [Latitude], [Longitude], GETDATE(), GETDATE())
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
			SELECT	COALESCE(OBJECT_NAME(@@PROCID) + ' - OutletID', 'PartnersOffers_Load_Outlet' + ' - OutletID')
				,	GETDATE()
				,	@Inserted
				,	@Updated
				,	@Deleted

			DELETE FROM @MergeCounts

END