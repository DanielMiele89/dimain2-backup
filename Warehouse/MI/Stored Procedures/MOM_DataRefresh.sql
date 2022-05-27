
-- =============================================
-- Author:		Rory Francis
-- Create date: 2019-04-25
-- Description:	Estimate the acquirer for all combinations
--				with a transaction in the last 6 months
-- =============================================

CREATE PROCEDURE [MI].[MOM_DataRefresh]
	
AS
BEGIN

	/*******************************************************************************************************************************************
		1. Fetch stats on all ConsumerCombinations with a transaction in the last 6 months
	*******************************************************************************************************************************************/

		DECLARE @ReportDate DATE = DATEADD(day, -183, GETDATE())

		IF OBJECT_ID('tempdb..#ConsumerCombinationsLastSixMonths') IS NOT NULL DROP TABLE #ConsumerCombinationsLastSixMonths
		SELECT ct.ConsumerCombinationID
			 , SUM(ct.Amount) AS Amount
			 , MAX(ct.TranDate) AS MaxTranDate
		INTO #ConsumerCombinationsLastSixMonths
		FROM Relational.ConsumerTransaction ct
		WHERE TranDate > @ReportDate
		GROUP BY ct.ConsumerCombinationID

		IF OBJECT_ID('tempdb..#ConsumerCombinationsLastSixMonths_CC') IS NOT NULL DROP TABLE #ConsumerCombinationsLastSixMonths_CC
		SELECT ct.ConsumerCombinationID
			 , SUM(ct.Amount) AS Amount
			 , MAX(ct.TranDate) AS MaxTranDate
		INTO #ConsumerCombinationsLastSixMonths_CC
		FROM Relational.ConsumerTransaction_CreditCard ct
		WHERE TranDate > @ReportDate
		GROUP BY ct.ConsumerCombinationID

		IF OBJECT_ID('tempdb..#ConsumerCombinations') IS NOT NULL DROP TABLE #ConsumerCombinations
		SELECT ct.ConsumerCombinationID
			 , SUM(ct.Amount) AS Amount
			 , MAX(ct.MaxTranDate) AS MaxTranDate
		INTO #ConsumerCombinations
		FROM (SELECT ConsumerCombinationID
				   , Amount
				   , MaxTranDate
			  FROM #ConsumerCombinationsLastSixMonths
			  UNION ALL
			  SELECT ConsumerCombinationID
				   , Amount
				   , MaxTranDate
			  FROM #ConsumerCombinationsLastSixMonths_CC) ct
		GROUP BY ct.ConsumerCombinationID

		CREATE CLUSTERED INDEX CIX_CCID ON #ConsumerCombinations (ConsumerCombinationID)

	/*******************************************************************************************************************************************
		2. Fetch all GB ConsumerCombinations, coercing MIDs & OriginatorIDs into required formats
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#ConsumerCombination_Temp') IS NOT NULL DROP TABLE #ConsumerCombination_Temp
		SELECT cc.ConsumerCombinationID
			 , cc.BrandID
			 , c.Amount
			 , c.MaxTranDate
			 , REPLACE(cc.MID, ' ', '') AS MID
			 , REPLACE(cc.OriginatorID, ' ', '') AS OriginatorID
			 , COALESCE(CONVERT(VARCHAR(25), TRY_CONVERT(BIGINT, REPLACE(cc.MID, ' ', ''))), MID) AS MID_INT
			 , COALESCE(CONVERT(VARCHAR(25), TRY_CONVERT(BIGINT, REPLACE(cc.OriginatorID, ' ', ''))), 'Unknown acquirer') AS OriginatorID_INT
		INTO #ConsumerCombination_Temp
		FROM Relational.ConsumerCombination cc
		INNER JOIN #ConsumerCombinations c
			ON c.ConsumerCombinationID = cc.ConsumerCombinationID
		WHERE LocationCountry = 'GB'

		IF OBJECT_ID('tempdb..#ConsumerCombination') IS NOT NULL DROP TABLE #ConsumerCombination
		SELECT ConsumerCombinationID
			 , BrandID
			 , Amount
			 , MaxTranDate
			 , MID
			 , OriginatorID
			 , MID_INT
			 , OriginatorID_INT
			 , OriginatorID_INT_Length
			 , MID_INT_Length
			 , MID_Length
			 , CASE
					WHEN OriginatorID_INT_Length >= 4 AND (LEFT(OriginatorID_INT, 4) = '4929' OR OriginatorID_INT = '457915') THEN 7
					WHEN OriginatorID_INT IN ('467858', '474510', '491678', '491677', '406418', '454706', '477902', '474509') THEN 8
					WHEN OriginatorID_INT IN ('424192', '425518', '424191') THEN 15
					WHEN OriginatorID_INT IN ('446365') THEN 10
					WHEN OriginatorID_INT IN ('483050') THEN 8
					WHEN OriginatorID_INT IN ('255', '256') THEN 6 -- check
					WHEN OriginatorID_INT IN ('417776') THEN 10 -- check
					WHEN OriginatorID_INT IN ('407370', '424469', '424500', '431320', '431321', '431323', '431326', '431327', '431328', '438218', '446366') THEN 10
					WHEN OriginatorID_INT IN ('411975') THEN 15
					ELSE NULL
			   END AS Digits
		INTO #ConsumerCombination
		FROM (SELECT ConsumerCombinationID
				   , BrandID
				   , Amount
				   , MaxTranDate
	  			   , MID
	  			   , OriginatorID
	  			   , MID_INT
	  			   , OriginatorID_INT
	  			   , LEN(OriginatorID_INT) AS OriginatorID_INT_Length
	  			   , LEN(MID_INT) AS MID_INT_Length
	  			   , LEN(MID) AS MID_Length
				FROM #ConsumerCombination_Temp) cc

	/*******************************************************************************************************************************************
		3. Estimate the acquirer based on the MID & OriginatorID
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#ConsumerCombination_Acquirer') IS NOT NULL DROP TABLE #ConsumerCombination_Acquirer
		SELECT ConsumerCombinationID
			 , BrandID
			 , Amount
			 , MaxTranDate
			 , MID
			 , OriginatorID
			 , MID_INT
			 , OriginatorID_INT
			 , OriginatorID_INT_Length
			 , MID_INT_Length
			 , MID_Length
			 , Digits
			 , CASE
			
					WHEN OriginatorID_INT = 'Unknown acquirer' THEN 7	-- If OriginatorID is not an integer then 7

					-- barclaycard business
					WHEN OriginatorID_INT_Length >= 4 AND (LEFT(OriginatorID_INT, 4) = '4929' OR OriginatorID_INT = '457915') AND MID_Length >= Digits AND MID_INT = CONVERT(BIGINT, SUBSTRING(MID, MID_Length - Digits + 1, MID_Length)) THEN 1

					-- worldpay
					WHEN OriginatorID_INT IN (467858, 474510, 491678, 491677, 406418, 454706, 477902, 474509) THEN CASE
																														WHEN MID_Length >= Digits AND MID_INT = CONVERT(BIGINT, SUBSTRING(MID, MID_Length - Digits + 1, MID_Length)) THEN 2
																														ELSE 7
																												   END

					-- cardnet
					WHEN OriginatorID_INT IN (401947, 408532) THEN 3
					WHEN OriginatorID_INT IN (424192, 425518, 424191) THEN CASE
																   				WHEN MID_Length >= Digits AND MID_INT = CONVERT(BIGINT, SUBSTRING(MID, MID_Length - Digits + 1, MID_Length)) AND LEFT(MID, 4) = '5404' THEN 3
																   				ELSE 7
																		   END

					-- Global Payments
					WHEN OriginatorID_INT IN (483050) AND MID_Length >= Digits AND MID_INT = CONVERT(BIGINT, SUBSTRING(MID, MID_Length - Digits + 1, MID_Length)) AND RIGHT(MID, 1) = '1' THEN 4 --- exlcude 0's
					WHEN OriginatorID_INT IN (442471) THEN 4

					-- Elavon
					WHEN OriginatorID_INT IN (446365) AND MID_Length >= Digits AND MID_INT = CONVERT(BIGINT, SUBSTRING(MID, MID_Length - Digits + 1, MID_Length)) THEN 5

					-- odd
					WHEN OriginatorID_INT IN (255, 256) THEN 6 -- check

					-- Interpay
					WHEN OriginatorID_INT IN (417776) THEN 10 -- check

					-- Elavon / Foreign
					WHEN OriginatorID_INT IN (407370, 424469, 424500, 431320, 431321, 431323, 431326, 431327, 431328, 438218, 446366) THEN CASE
																																				WHEN MID_Length >= Digits AND MID_INT = CONVERT(BIGINT, SUBSTRING(MID, MID_Length - Digits + 1, MID_Length)) AND LEFT(MID, 4) IN ('2100', '1001') THEN 5
																																				ELSE 9
																																			END

					-- Foreign
					WHEN OriginatorID_INT IN (450306, 450744, 455358, 459519, 467989, 467990, 477127, 479262, 498750, 499876, 499886) THEN 9

					-- HBOS
					WHEN OriginatorID_INT IN (405657) THEN 11

					-- chase
					WHEN OriginatorID_INT IN (431322, 431330, 431319, 431329) THEN 12

					-- FDMS
					WHEN OriginatorID_INT IN (411975) AND MID_Length >= Digits AND MID_INT = CONVERT(BIGINT, SUBSTRING(MID, MID_Length - Digits + 1, MID_Length)) AND LEFT(MID, 4) = '5203' THEN 14
					ELSE 7
			   END AS EstimatedAcquirerID
		INTO #ConsumerCombination_Acquirer
		FROM #ConsumerCombination
	

	/*******************************************************************************************************************************************
		4. For certain listed brands, replace unknown acquirers with specifed ones
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#ConsumerCombination_Override') IS NOT NULL DROP TABLE #ConsumerCombination_Override
		SELECT cca.ConsumerCombinationID
			 , cca.BrandID
			 , cca.Amount
			 , cca.MaxTranDate
			 , cca.MID
			 , cca.OriginatorID
			 , cca.MID_INT
			 , cca.OriginatorID_INT
			 , cca.OriginatorID_INT_Length
			 , cca.MID_INT_Length
			 , cca.MID_Length
			 , cca.Digits
			 , cca.EstimatedAcquirerID
			 , CASE
					WHEN cca.EstimatedAcquirerID = 7 AND bao.AcquirerID IS NOT NULL THEN bao.AcquirerID
					ELSE cca.EstimatedAcquirerID
			   END AcquirerOverrideID
		INTO #ConsumerCombination_Override
		FROM #ConsumerCombination_Acquirer cca
		LEFT JOIN MI.RetailerTrackingBrandAcquirerOverride bao
			ON cca.BrandID = bao.BrandID
	

	/*******************************************************************************************************************************************
		5. Run final update on remaining combinations with unknown acquirers
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#ConsumerCombination_Acquirer_Override') IS NOT NULL DROP TABLE #ConsumerCombination_Acquirer_Override
		SELECT cca.ConsumerCombinationID
			 , cca.BrandID
			 , cca.Amount
			 , cca.MaxTranDate
			 , cca.MID
			 , cca.OriginatorID
			 , cca.MID_INT
			 , cca.OriginatorID_INT
			 , cca.OriginatorID_INT_Length
			 , cca.MID_INT_Length
			 , cca.MID_Length
			 , cca.Digits
			 , cca.EstimatedAcquirerID
			 , cca.AcquirerOverrideID
			 , CASE
					WHEN cca.AcquirerOverrideID != 7 THEN cca.AcquirerOverrideID
					ELSE CASE
		       				WHEN cca.MID_INT_Length = 7 THEN 1
		       				WHEN cca.MID_INT_Length = 8 AND SUBSTRING(cca.MID_INT, cca.MID_Length, 99) = '1' THEN 4
		       				WHEN cca.MID_INT_Length = 8 THEN 2
		       				WHEN cca.MID_INT_Length = 10 AND LEFT(cca.MID_INT, 4) IN ('2100', '1001') THEN 5
		       				WHEN cca.MID_INT_Length = 15 AND LEFT(cca.MID_INT, 4) IN ('5404', '3366') THEN 3
		       				WHEN cca.MID_INT_Length = 15 AND LEFT(cca.MID_INT, 4) IN ('5203') THEN 14
		       				ELSE cca.AcquirerOverrideID
						 END
			   END AS NewAcquirerOverrideID
		INTO #ConsumerCombination_Acquirer_Override
		FROM #ConsumerCombination_Override cca
	

	/*******************************************************************************************************************************************
		6. Find all brands with multiple acquirers
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#SplitAcquirers') IS NOT NULL DROP TABLE #SplitAcquirers
		SELECT BrandID
			 , COUNT(DISTINCT NewAcquirerOverrideID) AS Acquirers
		INTO #SplitAcquirers
		FROM #ConsumerCombination_Acquirer_Override
		WHERE NewAcquirerOverrideID != 7
		GROUP BY BrandID
	

	/*******************************************************************************************************************************************
		7. Fetch the most recent locations for each combination
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#Location') IS NOT NULL DROP TABLE #Location
		SELECT l.ConsumerCombinationID
			 , l.LocationAddress
		INTO #Location
		FROM (SELECT ConsumerCombinationID
				   , LocationID
				   , LocationAddress
				   , MAX(LocationID) OVER (PARTITION BY ConsumerCombinationID) AS MaxLocationID
			  FROM Relational.Location) l
		WHERE LocationID = MaxLocationID
	

	/*******************************************************************************************************************************************
		8. Partially populate the final dataset, splitting out into two steps to prevent excess processing time
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#PreInsert') IS NOT NULL DROP TABLE #PreInsert
		SELECT cca.BrandID
			 , br.BrandName
			 , cca.ConsumerCombinationID
			 , cca.MaxTranDate
			 , cca.Amount
			 , lo.LocationAddress
			 , cca.NewAcquirerOverrideID AS AcquirerID
			 , ac.AcquirerName
			 , CASE
					WHEN sa.Acquirers > 1 THEN 1
					ELSE 0
			   END AS SplitAcquirer
		INTO #PreInsert
		FROM #ConsumerCombination_Acquirer_Override cca
		INNER JOIN #SplitAcquirers sa
			ON cca.BrandID = sa.BrandID
		INNER JOIN Relational.Brand br
			ON cca.BrandID = br.BrandID
		LEFT JOIN Relational.Acquirer ac
			ON cca.NewAcquirerOverrideID = ac.AcquirerID
		LEFT JOIN #Location lo
			ON cca.ConsumerCombinationID = lo.ConsumerCombinationID

		CREATE CLUSTERED INDEX CIX_CCID ON #PreInsert (ConsumerCombinationID)
	

	/*******************************************************************************************************************************************
		9. Truncate and repopulate the final table
	*******************************************************************************************************************************************/

		TRUNCATE TABLE Staging.MOM_Last6Months
		INSERT INTO Staging.MOM_Last6Months (BrandID
										   , BrandName
										   , ConsumerCombinationID
										   , MID
										   , Narrative
										   , LastTranDate
										   , Amount
										   , LocationAddress
										   , OriginatorID
										   , MCCID
										   , MCCDesc
										   , AcquirerID
										   , AcquirerName
										   , SplitAcquirer)
		SELECT pri.BrandID
			 , pri.BrandName
			 , pri.ConsumerCombinationID
			 , cc.MID
			 , cc.Narrative
			 , pri.MaxTranDate
			 , pri.Amount
			 , pri.LocationAddress
			 , cc.OriginatorID
			 , cc.MCCID
			 , mcc.MCCDesc
			 , pri.AcquirerID
			 , pri.AcquirerName
			 , pri.SplitAcquirer
		FROM #PreInsert pri
		INNER JOIN Relational.ConsumerCombination cc
			ON pri.ConsumerCombinationID = cc.ConsumerCombinationID
		LEFT JOIN Relational.MCCList mcc
			ON cc.MCCID = mcc.MCCID
	

	/*******************************************************************************************************************************************
		10. Add new entries to MI.RetailerTrackingAcquirer
	*******************************************************************************************************************************************/
	
		INSERT INTO MI.RetailerTrackingAcquirer
		SELECT mm.ConsumerCombinationID
			 , mm.AcquirerID
			 , mm.Amount
			 , 1
			 , mm.LastTranDate
		FROM Staging.MOM_Last6Months mm
		WHERE NOT EXISTS (SELECT 1
						  FROM MI.RetailerTrackingAcquirer rta
						  WHERE mm.ConsumerCombinationID = rta.ConsumerCombinationID)


	/*******************************************************************************************************************************************
		11. Update MI.RetailerTrackingAcquirer
	*******************************************************************************************************************************************/

		UPDATE rta
		SET rta.AcquirerID = mm.AcquirerID
		  , rta.AnnualSpend = mm.Amount
		  , rta.TransactedDate = mm.LastTranDate
		FROM MI.RetailerTrackingAcquirer rta
		INNER JOIN Staging.MOM_Last6Months mm
			ON rta.ConsumerCombinationID = mm.ConsumerCombinationID

END