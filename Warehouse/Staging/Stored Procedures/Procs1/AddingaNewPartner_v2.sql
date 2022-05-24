/*--------------------------------------

	Author:		Rory Francis

	Date:		5 March 2019

	Purpose:	Adding new Partner infor to DIMAIN & RewardBI

---------------------------------------*/

CREATE PROCEDURE [Staging].[AddingaNewPartner_v2] (@PartnerID INT
												, @BrandID INT
												, @SDate DATE
												, @TierID TINYINT
												, @IsPointOfSale BIT
												, @IsDirectDebit BIT
												, @PrimaryPartnerID INT
												, @AddPartnerToWarehouse BIT

												, @POS_AcquireLength INT = 12
												, @POS_LapsedLength INT = 6
												, @POS_ShopperLength INT = 0
												
												, @IsCore BIT = 0
												, @RBSFunded BIT = 0

												, @DD_AcquireLength INT = 12
												, @DD_LapsedLength INT = 6
												, @DD_ShopperLength INT = 0)

With Execute as Owner as
BEGIN
SET NOCOUNT ON

--DECLARE @PID INT = 4731
--	  , @BID INT = 2626
--	  , @SDate DATE = '2019-03-14'
--	  , @TierID TINYINT = 1
--	  , @IsPointOfSale BIT = 1
--	  , @IsDirectDebit BIT = 0
	  
--	  , @POS_AcquireLength INT = 300
--	  , @POS_LapsedLength INT = 2
--	  , @POS_ShopperLength INT = 0

--	  , @IsCore BIT = 0
--	  , @RBSFunded BIT = 0
	  
--	  , @DD_AcquireLength INT = 12
--	  , @DD_LapsedLength INT = 6
--	  , @DD_ShopperLength INT = 0

	DECLARE @SequenceNumber INT = (SELECT Max(SequenceNumber) + 1 FROM Relational.Partner)
		  , @PID INT = @PartnerID
		  , @PPID INT = @PrimaryPartnerID
		  , @PartnerName VARCHAR(50) = (SELECT Name FROM SLC_REPL.dbo.Partner WHERE ID = @PartnerID)
		  , @BID INT = @BrandID
		  , @BrandName VARCHAR(50) = (SELECT BrandName FROM Relational.Brand WHERE BrandID = @BrandID)
		  , @SectorID TINYINT = (SELECT SectorID FROM Relational.Brand WHERE BrandID = @BrandID)
		  , @SectorName VARCHAR(50) = (SELECT bs.SectorName FROM Relational.Brand br INNER JOIN Relational.BrandSector bs ON br.SectorID = bs.SectorID WHERE BrandID = @BrandID)
		  , @StartDate DATE = @SDate
		  
		  , @IsPOS BIT = @IsPointOfSale
		  , @IsDD BIT = @IsDirectDebit
								
		  , @POS_Acquire INT = @POS_AcquireLength
		  , @POS_Lapsed INT = @POS_LapsedLength
		  , @POS_Shopper INT = @POS_ShopperLength

		  , @DD_Acquire INT = @DD_AcquireLength
		  , @DD_Lapsed INT = @DD_LapsedLength
		  , @DD_Shopper INT = @DD_ShopperLength
		  
	DECLARE @TransactionTypeID INT = (SELECT CASE
												WHEN CONVERT(INT, @IsPOS) = 1 AND CONVERT(INT, @IsDD) = 0 THEN 1
												WHEN CONVERT(INT, @IsPOS) = 0 AND CONVERT(INT, @IsDD) = 1 THEN 2
												WHEN CONVERT(INT, @IsPOS) = 1 AND CONVERT(INT, @IsDD) = 1 THEN 3
											 END)
		  , @TransactionTypeDesc VARCHAR(25) = (SELECT CASE
															WHEN CONVERT(INT, @IsPOS) = 1 AND CONVERT(INT, @IsDD) = 0 THEN 'Point of Sale'
															WHEN CONVERT(INT, @IsPOS) = 0 AND CONVERT(INT, @IsDD) = 1 THEN 'Direct Debit'
															WHEN CONVERT(INT, @IsPOS) = 1 AND CONVERT(INT, @IsDD) = 1 THEN 'Point of Sale & Direct Debit'
													   END)



		/*-------------------------------------------------------*/
		 ----------------Updating Relational.Partner---------------
		/*-------------------------------------------------------*/

		IF NOT EXISTS (SELECT 1 FROM Relational.Partner WHERE PartnerID = @PID) AND @AddPartnerToWarehouse = 1
			BEGIN
				INSERT INTO Relational.Partner (SequenceNumber
											  , PartnerID
											  , PartnerName
											  , BrandID
											  , BrandName
											  , CurrentlyActive
											  , AccountManager
											  , TransactionTypeID)
											  --, IsPointOfSale
											  --, IsDirectDebit)
				SELECT @SequenceNumber
					 , @PID
					 , @PartnerName
					 , @BID
					 , @BrandName
					 , 0
					 , 'Unassigned'
					 , @TransactionTypeID
			END

		SELECT 'TableName' as [Warehouse.Relational.Partner]
			 , *
		FROM Relational.Partner
		WHERE PartnerID = @PID

		/*-------------------------------------------------------*/
		 -----------Updating Relational.Partner_CBPDates----------
		/*-------------------------------------------------------*/

			IF NOT EXISTS (SELECT 1 FROM Relational.Partner_CBPDates WHERE PartnerID = @PID AND (Scheme_EndDate IS NULL OR Scheme_EndDate > GETDATE())) AND @AddPartnerToWarehouse = 1
				BEGIN
					INSERT INTO Relational.Partner_CBPDates (PartnerID
														   , Scheme_StartDate
														   , Scheme_EndDate
														   , Coalition_Member)
					SELECT @PID
						 , @StartDate
						 , CONVERT(DATE, NULL)
						 , 0
				END

			SELECT 'TableName' as [Warehouse.Relational.Partner_CBPDates]
				 , *
			FROM Relational.Partner_CBPDates
			WHERE PartnerID = @PID


		/*---------------------------------------------------*/
		 --------Create Partners_IncFuture Table Entry--------
		/*---------------------------------------------------*/

			IF NOT EXISTS (SELECT 1 FROM Staging.Partners_IncFuture WHERE PartnerID = @PID AND BrandID = @BID) AND @AddPartnerToWarehouse = 1
				BEGIN
					INSERT INTO Staging.Partners_IncFuture (PartnerID
														  , PartnerName
														  , BrandID
														  , BrandName)
					SELECT @PID
						 , @PartnerName
						 , @BID
						 , @BrandName
				END

			SELECT 'TableName' as [Warehouse.Staging.Partners_IncFuture]
				 , *
			FROM Staging.Partners_IncFuture
			WHERE PartnerID = @PID

		/*----------------------------------------------------------------------------------*/
		 ------ Create Segmentation.ROC_Shopper_Segment_Partner_Settings Table Entry------
		/*----------------------------------------------------------------------------------*/

			--UPDATE Segmentation.ROC_Shopper_Segment_Partner_Settings
			--SET EndDate = GETDATE()
			--WHERE PartnerID = @PID
			--AND EndDate IS NULL
			--AND (Acquire != @POS_Acquire
			--  OR Lapsed != @POS_Lapsed
			--  OR Shopper != @POS_Shopper)

			IF NOT EXISTS (SELECT 1 FROM Segmentation.ROC_Shopper_Segment_Partner_Settings WHERE PartnerID = @PID AND (EndDate IS NULL OR EndDate > GETDATE())) AND @IsPOS = 1 AND @AddPartnerToWarehouse = 1 AND @PID = @PPID
				BEGIN
					INSERT INTO Segmentation.ROC_Shopper_Segment_Partner_Settings (PartnerID
																				 , Acquire
																				 , Lapsed
																				 , Shopper
																				 , AutoRun
																				 , StartDate
																				 , EndDate)
					SELECT @PID
						 , @POS_Acquire
						 , @POS_Lapsed
						 , @POS_Shopper
						 , 1 AS AutoRun
						 , GETDATE() AS StartDate
						 , NULL AS EndDate
				END

			SELECT 'TableName' as [Segmentation.ROC_Shopper_Segment_Partner_Settings]
				 , *
			FROM Segmentation.ROC_Shopper_Segment_Partner_Settings
			WHERE PartnerID = @PID
			ORDER BY StartDate

		/*----------------------------------------------------------------------------------*/
		 ------Create Segmentation.PartnerSettings_DD Table Entry------
		/*----------------------------------------------------------------------------------*/

			UPDATE Segmentation.PartnerSettings_DD
			SET EndDate = GETDATE()
			WHERE PartnerID = @PID
			AND EndDate IS NULL
			AND (Acquire != @DD_Acquire
			  OR Lapsed != @DD_Lapsed
			  OR Shopper != @DD_Shopper)

			IF NOT EXISTS (SELECT 1 FROM Segmentation.PartnerSettings_DD WHERE PartnerID = @PID AND (EndDate IS NULL OR EndDate > GETDATE())) AND @IsDD = 1 AND @AddPartnerToWarehouse = 1 AND @PID = @PPID
				BEGIN
					INSERT INTO Segmentation.PartnerSettings_DD (PartnerID
															   , Acquire
															   , Lapsed
															   , Shopper
															   , AutoRun
															   , StartDate
															   , EndDate)
					SELECT @PID
						 , @DD_Acquire
						 , @DD_Lapsed
						 , @DD_Shopper
						 , 1 AS AutoRun
						 , GETDATE() AS StartDate
						 , NULL AS EndDate
				END

			SELECT 'TableName' as [Segmentation.PartnerSettings_DD]
				 , *
			FROM Segmentation.PartnerSettings_DD
			WHERE PartnerID = @PID
			ORDER BY StartDate

		/*----------------------------------------------------------------------------------*/
		 -----Create [Segmentation].[ROC_Shopper_Segment_Partner_Settingsv2] Table Entry-----
		/*----------------------------------------------------------------------------------*/

			IF NOT EXISTS (SELECT 1 FROM Segmentation.ROC_Shopper_Segment_Partner_Settingsv2 WHERE PartnerID = @PID AND (EndDate IS NULL OR EndDate > GETDATE())) AND @IsPOS = 1
				BEGIN
					INSERT INTO Segmentation.ROC_Shopper_Segment_Partner_Settingsv2 (PartnerID
																				   , Acquire_Pct
																				   , Acquire
																				   , Lapsed
																				   , AutoRun
																				   , StartDate
																				   , EndDate)
					SELECT @PID
						 , 100 as Acquire_Pct
						 , @POS_Acquire
						 , @POS_Lapsed
						 , 1 AS AutoRun
						 , GETDATE() AS StartDate
						 , NULL AS EndDate
				END

			SELECT 'TableName' as [Segmentation.ROC_Shopper_Segment_Partner_Settingsv2]
				 , *
			FROM Segmentation.ROC_Shopper_Segment_Partner_Settingsv2
			WHERE PartnerID = @PID


		/*----------------------------------------------------------------------------------*/
		 -----Create nfi.Segmentation.PartnerSettings Table Entry-----
		/*----------------------------------------------------------------------------------*/

			IF NOT EXISTS (SELECT 1 FROM nfi.Segmentation.PartnerSettings WHERE PartnerID = @PID AND (EndDate IS NULL OR EndDate > GETDATE())) AND @IsPOS = 1 AND @PID = @PPID
				BEGIN
					INSERT INTO nfi.Segmentation.PartnerSettings (PartnerID
																, Lapsed	--	Actually Acquire
																, Existing	--	Actually Lapsed
																, RegisteredAtLeast
																, CtrlGrp
																, AutomaticRun
																, StartDate
																, EndDate)
					SELECT @PID
						 , @POS_Acquire
						 , @POS_Lapsed
						 , 1 as RegisteredAtLeast
						 , 0 as CtrlGrp
						 , 1 as AutomaticRun
						 , GETDATE() as StartDate
						 , NULL as EndDate
				END

			SELECT 'TableName' as [nfi.Segmentation.PartnerSettings]
				 , *
			FROM nfi.[Segmentation].[PartnerSettings]
			WHERE PartnerID = @PID


		/*----------------------------------------------------------------------------------*/
		 -----Create iron.PrimaryRetailerIdentification Table Entry-----
		/*----------------------------------------------------------------------------------*/
		
			IF @PID != @PrimaryPartnerID AND @PrimaryPartnerID IS NOT NULL
				BEGIN

					IF NOT EXISTS (SELECT 1 FROM Warehouse.APW.PartnerAlternate WHERE PartnerID = @PID AND AlternatePartnerID = @PrimaryPartnerID)
						BEGIN

							INSERT INTO Warehouse.APW.PartnerAlternate (PartnerID
																	  , AlternatePartnerID)
							SELECT @PID
								 , @PrimaryPartnerID
						END
						
				END

			SELECT 'TableName' as [Warehouse.APW.PartnerAlternate]
				 , *
			FROM Warehouse.APW.PartnerAlternate
			WHERE PartnerID = @PID

		/*----------------------------------------------------------------------------------*/
		 -----Create iron.PrimaryRetailerIdentification Table Entry-----
		/*----------------------------------------------------------------------------------*/
		
			IF @PID != @PrimaryPartnerID AND @PrimaryPartnerID IS NOT NULL
				BEGIN

					IF NOT EXISTS (SELECT 1 FROM nFI.APW.PartnerAlternate WHERE PartnerID = @PID AND AlternatePartnerID = @PrimaryPartnerID)
						BEGIN

							INSERT INTO nFI.APW.PartnerAlternate (PartnerID
																, AlternatePartnerID)
							SELECT @PID
								 , @PrimaryPartnerID
						END
						
				END

			SELECT 'TableName' as [nFI.APW.PartnerAlternate]
				 , *
			FROM nFI.APW.PartnerAlternate
			WHERE PartnerID = @PID

		/*----------------------------------------------------------------------------------*/
		 -----Create iron.PrimaryRetailerIdentification Table Entry-----
		/*----------------------------------------------------------------------------------*/
		

			IF @PID = @PrimaryPartnerID
				BEGIN
					SET @PrimaryPartnerID = NULL
				END

			IF NOT EXISTS (SELECT 1 FROM iron.PrimaryRetailerIdentification WHERE PartnerID = @PID)
				BEGIN


					INSERT INTO iron.PrimaryRetailerIdentification (PartnerID
																  , PrimaryPartnerID)
					SELECT @PID
						 , @PrimaryPartnerID
				END

			SELECT 'TableName' as [iron.PrimaryRetailerIdentification]
				 , *
			FROM iron.PrimaryRetailerIdentification
			WHERE PartnerID = @PID


		/*----------------------------------------------------------------------------------*/
		 -----Create iron.PrimaryRetailerIdentification Table Entry-----
		/*----------------------------------------------------------------------------------*/

			IF NOT EXISTS (SELECT 1 FROM iron.PrimaryRetailerIdentification_Accounts WHERE PartnerID = @PID)
				BEGIN


					INSERT INTO iron.PrimaryRetailerIdentification_Accounts (PartnerID
																		   , PrimaryPartnerID)
					SELECT @PID
						 , @PrimaryPartnerID
				END

			SELECT 'TableName' as [iron.PrimaryRetailerIdentification_Accounts]
				 , *
			FROM iron.PrimaryRetailerIdentification_Accounts
			WHERE PartnerID = @PID



END
