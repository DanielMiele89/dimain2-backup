/*
-- REPLACEs this bunch of stored procedures:
EXEC WHB.PartnersOffers_IronOffer

*/
CREATE PROCEDURE [WHB].[PartnersOffers_IronOffer]

AS
BEGIN

	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);
	
	DECLARE @StoredProcedureName VARCHAR(100) = OBJECT_NAME(@@PROCID)
		,	@msg VARCHAR(200)
		,	@RowsAffected INT
		,	@Query VARCHAR(MAX)

	EXEC [Monitor].[ProcessLog_Insert] @StoredProcedureName, 'Started'

	BEGIN TRY
	
		/*******************************************************************************************************************************************
			1.	Create an IronOfferID for all new Offers that have been received
		*******************************************************************************************************************************************/
			
			INSERT INTO [WH_AllPublishers].[Derived].[OfferIDs]
			SELECT	DISTINCT
					ppl.PartnerID
				,	PublisherID = pl.ClubID
				,	PublisherID_RewardBI = pl.ClubID
				,	OfferCode = iof.OfferGUID
				,	OfferIDTypeID = 2	--	Bank Scheme Import to DIMAIN
				,	ImportDate = GETDATE()
			FROM [WHB].[Inbound_Offer] iof
			LEFT JOIN [SLC_REPL].[hydra].[PublisherLink] pl
				ON iof.PublisherGUID = pl.HydraPublisherID
			LEFT JOIN [SLC_REPL].[hydra].[PartnerPublisherLink] ppl
				ON iof.RetailerGUID = ppl.HydraPartnerID
	--			AND iof.PublisherGUID = ppl.HydraPublisherID
				AND NOT EXISTS (SELECT 1
								FROM [SLC_REPL].[dbo].[Partner] pa
								WHERE ppl.PartnerID = pa.ID
								AND pa.Name LIKE '%amex%')
			WHERE NOT EXISTS (	SELECT 1
								FROM [WH_AllPublishers].[Derived].[OfferIDs] oi
								WHERE oi.OfferIDTypeID = 2
								AND iof.OfferGUID = oi.OfferCode
								AND pl.ClubID = oi.PublisherID
								AND pl.ClubID = oi.PublisherID_RewardBI)
			AND iof.OfferGUID NOT IN ('1C548443-58FA-424B-92D5-248A3EC73538')


		/*******************************************************************************************************************************************
			2.	Populate the [Derived].[IronOffer] table
		*******************************************************************************************************************************************/
		
			DECLARE @ClubID INT = 180

			TRUNCATE TABLE [Derived].[IronOffer]
			INSERT INTO [Derived].[IronOffer] (	IronOfferID
											,	IronOfferName
											,	HydraOfferID
											,	StartDate
											,	EndDate
											,	PartnerID
											,	IsAboveTheLine
											,	AutoAddToNewRegistrants
											,	IsDefaultCollateral
											,	IsSignedOff
											,	AreEligibleMembersCommitted
											,	AreControlMembersCommitted
											,	IsTriggerOffer
											,	TopCashBackRate
											,	SegmentName
											,	ClubID)
			SELECT	DISTINCT
					IronOfferID = CONVERT(INT, oi.IronOfferID)
				,	IronOfferName = CONVERT(NVARCHAR(200), iof.OfferName)
				,	HydraOfferID = iof.OfferGUID
				,	StartDate = CONVERT(DATETIME, iof.[StartDate])
				,	EndDate = CONVERT(DATETIME, iof.[EndDate])
				,	PartnerID = CONVERT(INT, oi.[PartnerID])
				,	IsAboveTheLine = NULL
				,	AutoAddToNewRegistrants = NULL
				,	IsDefaultCollateral = NULL
				,	IsSignedOff = CASE WHEN OfferStatusID = 5 THEN 0 ELSE 1 END
				,	AreEligibleMembersCommitted = NULL
				,	AreControlMembersCommitted = NULL
				,	IsTriggerOffer = NULL
				,	TopCashBackRate = NULL
				,	SegmentName =	CASE
										WHEN iof.OfferName LIKE '%Lapsed%' THEN 'Lapsed'
										WHEN iof.OfferName LIKE '%Lasped%' THEN 'Lapsed'
										WHEN iof.OfferName LIKE '%Acquire%' THEN 'Acquire'
										WHEN iof.OfferName LIKE '%Welcome%' THEN 'Welcome'
										WHEN iof.OfferName LIKE '%Shopper%' THEN 'Shopper'
										WHEN iof.OfferName LIKE '%Nursery%' THEN 'Shopper'
										WHEN iof.OfferName LIKE '%Lapsing%' THEN 'Shopper'
									END
				,	@ClubID
			FROM [WHB].[Inbound_Offer] iof
			INNER JOIN [WH_AllPublishers].[Derived].[OfferIDs] oi
				ON CONVERT(VARCHAR(64), iof.OfferGUID) = oi.OfferCode
			WHERE OfferDetailGUID IS NOT NULL
			AND OfferStatusID != 5
			AND EXISTS (SELECT	iof2.OfferGUID
							,	MAX(iof2.PublishedDate) AS PublishedDate
						FROM [WHB].[Inbound_Offer] iof2
						WHERE iof.OfferGUID = iof2.OfferGUID
						GROUP BY iof2.OfferGUID
						HAVING CONVERT(DATE, iof.PublishedDate) = MAX(CONVERT(DATE, iof2.PublishedDate)))

			UPDATE [Derived].[IronOffer]
			SET EndDate = DATEADD(HOUR, 1, EndDate)
			WHERE EndDate BETWEEN '2021-03-28' AND '2021-10-31'
			OR EndDate BETWEEN '2022-03-27' AND '2022-10-30'
			OR EndDate BETWEEN '2023-03-26' AND '2023-10-29'
			OR EndDate BETWEEN '2024-03-31' AND '2024-10-27'

			
			UPDATE [Derived].[IronOffer]
			SET StartDate = DATEADD(HOUR, 1, StartDate)
			WHERE DATEPART(HOUR, StartDate) = 23
			AND (StartDate BETWEEN '2021-03-28' AND '2021-10-31'
			OR StartDate BETWEEN '2022-03-27' AND '2022-10-30'
			OR StartDate BETWEEN '2023-03-26' AND '2023-10-29'
			OR StartDate BETWEEN '2024-03-31' AND '2024-10-27')

			UPDATE [Derived].[IronOffer]
			SET EndDate = DATEADD(S, -1, DATEADD(D, 1, CONVERT(DATETIME2, EndDate)))
			WHERE CONVERT(TIME, EndDate) = '00:00:00'

			UPDATE [Derived].[IronOffer]
			SET IronOfferName = 'BBX004/Acquire'
			,	SegmentName = 'Acquire'
			WHERE HydraOfferID = 'D28CE991-B45D-44EC-9EB5-908C4AC50026'

			UPDATE [Derived].[IronOffer]
			SET IronOfferName = REPLACE(IronOfferName, 'SIGBOX220', 'HS124')
			WHERE IronOfferID IN (-1255, -1248)

			UPDATE [Derived].[IronOffer]
			SET IronOfferName = REPLACE(IronOfferName, 'Lasped', 'Lapsed')
			WHERE IronOfferID IN (-1251, -1133, -1294, -1255)

			UPDATE [Derived].[IronOffer]
			SET IronOfferName = REPLACE(IronOfferName, 'Lased', 'Lapsed')
			WHERE IronOfferID IN (-1251, -1133, -1294)

			UPDATE [Derived].[IronOffer]
			SET IronOfferName = REPLACE(IronOfferName, 'PD002', 'PDO002')
			WHERE IronOfferID IN (-1165, -1159, -1112, -1023)

			UPDATE [Derived].[IronOffer]
			SET IronOfferName = REPLACE(IronOfferName, 'SYD004', 'SDY004')
			WHERE IronOfferID IN (-1066, -1065)

			UPDATE [Derived].[IronOffer]
			SET IronOfferName = IronOfferName + '/Acquire'
			WHERE IronOfferID IN (-3821, -2681)


		/*******************************************************************************************************************************************
			3.	Fetch Cashback Rate
		*******************************************************************************************************************************************/

			UPDATE iof
			SET TopCashbackRate = TCBR
			FROM [Derived].[IronOffer] iof
			CROSS APPLY (	SELECT MAX(MarketingRate) AS TCBR
							FROM [WHB].[Inbound_OfferDetail] iofd
							WHERE iof.HydraOfferID = iofd.OfferGUID) x
			WHERE iof.TopCashbackRate IS NULL


		/*******************************************************************************************************************************************
			3.	Work Out Campaign Type
		*******************************************************************************************************************************************/

			UPDATE i
			SET CampaignType = 'Tactical Campaign'
			FROM [Derived].[IronOffer] as i


		/*******************************************************************************************************************************************
			4.	Remove expired unsigned off offers
		*******************************************************************************************************************************************/

			DELETE iof
			FROM [Derived].[IronOffer] iof
			WHERE iof.IsAboveTheLine = 0 
			AND iof.IsDefaultCollateral = 0 
			AND iof.IsSignedOff = 0 
			AND iof.IsTriggerOffer = 0
			AND iof.EndDate < GETDATE()
	
			EXEC [Monitor].[ProcessLog_Insert] @StoredProcedureName, 'Finished'

			RETURN 0; -- normal exit here

	END TRY
	BEGIN CATCH		
		
		-- Grab the error details
			SELECT  
				@ERROR_NUMBER = ERROR_NUMBER(), 
				@ERROR_SEVERITY = ERROR_SEVERITY(), 
				@ERROR_STATE = ERROR_STATE(), 
				@ERROR_PROCEDURE = ERROR_PROCEDURE(),  
				@ERROR_LINE = ERROR_LINE(),   
				@ERROR_MESSAGE = ERROR_MESSAGE();
			SET @ERROR_PROCEDURE = ISNULL(@ERROR_PROCEDURE, OBJECT_NAME(@@PROCID))

			IF @@TRANCOUNT > 0 ROLLBACK TRAN;
			
		-- Insert the error into the ErrorLog
			INSERT INTO [Monitor].[ErrorLog] (ErrorDate, ProcedureName, ErrorLine, ErrorMessage, ErrorNumber, ErrorSeverity, ErrorState)
			VALUES (GETDATE(), @ERROR_PROCEDURE, @ERROR_LINE, @ERROR_MESSAGE, @ERROR_NUMBER, @ERROR_SEVERITY, @ERROR_STATE);	

		-- Regenerate an error to return to caller
			SET @ERROR_MESSAGE = 'Error ' + CAST(@ERROR_NUMBER AS VARCHAR(6)) + ' in [' + @ERROR_PROCEDURE + '] at Line ' + CAST(@ERROR_LINE AS VARCHAR(6)) + '; ' + @ERROR_MESSAGE; 
			RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE);  

		-- Return a failure
			RETURN -1;

	END CATCH

	RETURN 0; -- should never run

END
