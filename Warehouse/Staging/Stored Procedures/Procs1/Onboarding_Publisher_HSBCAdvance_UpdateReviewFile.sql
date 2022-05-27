/*

	Author:		Stuart Barnley

	Date:		10th October 2016

	Purpose:	To produce a list of MerchantIDs to be provided to CLS

*/


CREATE PROCEDURE [Staging].[Onboarding_Publisher_HSBCAdvance_UpdateReviewFile]
AS
BEGIN

	/*******************************************************************************************************************************************
		1.	Fetch list of all PartnerIDs in the file to prepare to loop through
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#PartnerIDsInFile') IS NOT NULL DROP TABLE #PartnerIDsInFile
		SELECT DISTINCT
			   ro.PartnerID
			 , pa.Name AS PartnerName
			 , DENSE_RANK() OVER (ORDER BY pa.Name) AS PartnerNumber
		INTO #PartnerIDsInFile
		FROM [Staging].[Onboarding_Publisher_HSBCAdvance_FileImport] fi
		INNER JOIN [SLC_REPL].[dbo].[RetailOutlet] ro
			ON fi.SiteID = ro.ID
		INNER JOIN [SLC_REPL].[dbo].[Partner] pa
			ON ro.PartnerID = pa.ID

	/*******************************************************************************************************************************************
		2.	Delcare variables and begin looping throguh PartnerIDs
	*******************************************************************************************************************************************/

		DECLARE @PartnerNumber INT = 1
			  , @MaxPartnerNumber INT = (SELECT MAX(PartnerNumber) FROM #PartnerIDsInFile)
			  , @PartnerID INT


		WHILE @PartnerNumber <= @MaxPartnerNumber
			BEGIN

			/*******************************************************************************************************************************************
				2.1.	Fetch the PartnerID for this loop and any alternate PartnerIDs
			*******************************************************************************************************************************************/

				SELECT @PartnerID = PartnerID
				FROM #PartnerIDsInFile
				WHERE PartnerNumber = @PartnerNumber

				IF OBJECT_ID('tempdb..#PartnerIDs') IS NOT NULL DROP TABLE #PartnerIDs
				SELECT CONVERT(INT, pa.ID) AS ID
					 , pa.Name
					 , pa.RegisteredName
				INTO #PartnerIDs
				FROM [SLC_REPL].[dbo].[Partner] pa
				WHERE pa.ID = @PartnerID

				INSERT INTO #PartnerIDs
				SELECT CONVERT(INT, pa.ID) AS ID
					 , pa.Name
					 , pa.RegisteredName
				FROM #PartnerIDs p
				INNER JOIN [iron].[PrimaryRetailerIdentification] pri
					ON p.ID = COALESCE(pri.PrimaryPartnerID, pri.PartnerID)
				INNER JOIN [SLC_REPL].[dbo].[Partner] pa
					ON pri.PartnerID = pa.ID
				WHERE pa.[Name] NOT LIKE '%amex%'
				AND pa.[Name] NOT LIKE '%archive%'
				AND pa.ID != p.ID
				AND EXISTS (	SELECT 1
								FROM [SLC_REPL].[dbo].[RetailOutlet] ro
								WHERE pa.ID = ro.PartnerID)
				AND NOT EXISTS (SELECT 1
								FROM #PartnerIDs pe
								WHERE pa.ID = pe.ID)

				INSERT INTO #PartnerIDs
				SELECT CONVERT(INT, pa.ID) AS ID
					 , pa.Name
					 , pa.RegisteredName
				FROM #PartnerIDs p
				INNER JOIN [iron].[PrimaryRetailerIdentification] pri
					ON p.ID = COALESCE(pri.PartnerID, pri.PrimaryPartnerID)
				INNER JOIN [SLC_REPL].[dbo].[Partner] pa
					ON pri.PrimaryPartnerID = pa.ID
				WHERE pa.[Name] NOT LIKE '%amex%'
				AND pa.[Name] NOT LIKE '%archive%'
				AND pa.ID != p.ID
				AND EXISTS (	SELECT 1
								FROM [SLC_REPL].[dbo].[RetailOutlet] ro
								WHERE pa.ID = ro.PartnerID)
				AND NOT EXISTS (SELECT 1
								FROM #PartnerIDs pe
								WHERE pa.ID = pe.ID)

			/*******************************************************************************************************************************************
				2.2.	Fetch the all MID details for the looped PartnerID
			*******************************************************************************************************************************************/
		
				IF OBJECT_ID('tempdb..#RetailOutlets') IS NOT NULL DROP TABLE #RetailOutlets
				SELECT *
				INTO #RetailOutlets
				FROM [SLC_REPL].[dbo].[RetailOutlet] ro
				WHERE EXISTS (	SELECT 1
								FROM #PartnerIDs pa
								WHERE ro.PartnerID = pa.ID)

			/*******************************************************************************************************************************************
				2.3.	Fetch the all rows to review for the looped PartnerID
			*******************************************************************************************************************************************/

				IF OBJECT_ID('tempdb..#HSBCAdvance_FileImport') IS NOT NULL DROP TABLE #HSBCAdvance_FileImport
				SELECT ActionCode AS InitialActionCode 
					 , *
				INTO #HSBCAdvance_FileImport
				FROM [Staging].[Onboarding_Publisher_HSBCAdvance_FileImport] fi
				WHERE EXISTS (	SELECT 1
								FROM #RetailOutlets ro
								WHERE fi.SiteID = ro.ID)


			/*******************************************************************************************************************************************
				2.4.	Update the action codes of the validation file based on whether the MID Mastercard have matched to is
						incentivised on one of the Partners selected in step 2.1.
			*******************************************************************************************************************************************/

				UPDATE fi
				SET ActionCode = 'N'
				FROM #HSBCAdvance_FileImport fi
				WHERE fi.MC_ClearingAcquiringMerchantID != ''
				AND NOT EXISTS (	SELECT 1
									FROM #RetailOutlets ro
									WHERE COALESCE(CONVERT(VARCHAR(20), TRY_CONVERT(BIGINT, fi.MC_ClearingAcquiringMerchantID)), fi.MC_ClearingAcquiringMerchantID) = COALESCE(CONVERT(VARCHAR(20), TRY_CONVERT(BIGINT, ro.MerchantID)), ro.MerchantID))

				UPDATE fi
				SET ActionCode = 'M'
				FROM #HSBCAdvance_FileImport fi
				WHERE fi.ActionCode = 'Q'
					
				UPDATE fi
				SET ActionCode = 'N'
				FROM #HSBCAdvance_FileImport fi
				WHERE fi.ActionCode = 'D'


			/*******************************************************************************************************************************************
				2.5.	Update the imported file with the updated action codes
			*******************************************************************************************************************************************/

				UPDATE fin
				SET fin.PassThru1 = ro.PartnerID
				  , fin.PassThru2 = ro.ID
				FROM #HSBCAdvance_FileImport fin
				INNER JOIN #RetailOutlets ro
					ON fin.MC_ClearingAcquiringMerchantID = ro.MerchantID
				WHERE ActionCode = 'M'

				UPDATE fi
				SET fi.ActionCode = fit.ActionCode
				  , fi.PassThru1 = fit.PassThru1
				  , fi.PassThru2 = fit.PassThru2
				  , fi.IsFileReviewed = 1
				FROM [Staging].[Onboarding_Publisher_HSBCAdvance_FileImport] fi
				INNER JOIN #HSBCAdvance_FileImport fit
					ON fi.SiteID = fit.SiteID
					AND fi.AcquiringMerchantID = fit.AcquiringMerchantID
					AND fi.MC_ClearingAcquiringMerchantID = fit.MC_ClearingAcquiringMerchantID
					AND fi.ActionCode = fit.InitialActionCode
					AND fi.Comments = fit.Comments
					AND fi.MC_Location = fit.MC_Location
					AND fi.MerchantDBAName = fit.MerchantDBAName
					AND fi.MC_MerchantDBAName = fit.MC_MerchantDBAName
					AND fi.MerchantAddress = fit.MerchantAddress
					AND fi.MC_MerchantAddress = fit.MC_MerchantAddress
					AND fi.MerchantCity = fit.MerchantCity
					AND fi.MC_MerchantCity = fit.MC_MerchantCity
					AND fi.MerchantPostalCode = fit.MerchantPostalCode
					AND fi.MC_MerchantPostalCode = fit.MC_MerchantPostalCode


			/*******************************************************************************************************************************************
				2.6.	Move to next PartnerID
			*******************************************************************************************************************************************/

				SET @PartnerNumber = @PartnerNumber + 1

			END


END