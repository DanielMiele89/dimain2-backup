
/*

Author:		Rory Francis
Date:		1st January 2020
Purpose:	To add customers to the table storing whether they or on the existing OPE or OPE 2.0

Notes:		

*/

CREATE PROCEDURE [Lion].[AddCustomersToOPERollout] (@NewPercentageForNewOPE INT)
AS
	BEGIN

	/*******************************************************************************************************************************************
		1. Fetching Marketable email base
	*******************************************************************************************************************************************/
	   
		/***************************************************************************************************
			1.1. Fetch hardbounced customers to exclude
		***************************************************************************************************/
	
			IF OBJECT_ID('tempdb..#Hardbounce') IS NOT NULL DROP TABLE #Hardbounce;
			WITH
			HardBounce AS (SELECT FanID
								, MAX(EventDateTime) AS HardBounceDate
						   FROM [Relational].[EmailEvent] ee
						   WHERE EXISTS (SELECT 1
										 FROM [Relational].[Customer] cu
										 WHERE ee.FanID = cu.FanID
										 AND cu.CurrentlyActive = 1
										 AND cu.MarketableByEmail = 1)
						   GROUP BY FanID
						   HAVING MAX(EventDateTime) = MAX(CASE WHEN EmailEventCodeID = 702 THEN EventDateTime END))

			SELECT hb.FanID
				 , hb.HardBounceDate
			INTO #Hardbounce
			FROM HardBounce hb

			CREATE CLUSTERED INDEX CIX_FanID ON #Hardbounce (FanID)

			DELETE hb
			FROM #Hardbounce hb
			INNER JOIN [Staging].[Customer_EmailAddressChanges_20150101] eac
				 ON hb.FanID = eac.FanID
			WHERE hb.HardBounceDate < eac.DateChanged


		/***************************************************************************************************
			1.2. Fetch marketable email base
		***************************************************************************************************/

			IF OBJECT_ID('tempdb..#Email_Base') IS NOT NULL DROP TABLE #Email_Base
			SELECT c.FanID
			INTO #Email_Base
			FROM [Relational].[Customer] c
			INNER JOIN [SmartEmail].[TriggerEmailDailyFile_Calculated] tedf
				ON c.FanID = tedf.FanID
				And	(tedf.IsCredit = 1 OR tedf.IsDebit = 1)
			WHERE c.Marketablebyemail = 1
			AND c.CurrentlyActive = 1
			AND LEN(c.PostCode) >= 3
			AND NOT EXISTS (SELECT 1
							FROM [Relational].[SmartFocusUnsubscribes] sfdun
							WHERE c.FanID = sfdun.FanID
							AND sfdun.EndDate IS NULL)
			AND NOT EXISTS (SELECT 1
							FROM #Hardbounce hb
							WHERE c.FanID = hb.FanID)
			GROUP BY c.FanID
				   , c.CompositeID

			CREATE NONCLUSTERED COLUMNSTORE INDEX CSI_All ON #Email_Base (FanID)
	
			DROP TABLE #Hardbounce


	/*******************************************************************************************************************************************
		2. Append [Lion].[LionSend_OPERollout]
	*******************************************************************************************************************************************/

		INSERT INTO [Lion].[LionSend_OPERollout]
		SELECT FanID
			 , 0 AS OnNewOPE
			 , GETDATE()
			 , NULL
		FROM #Email_Base eb
		WHERE NOT EXISTS (SELECT 1
						  FROM [Lion].[LionSend_OPERollout] lsr
						  WHERE eb.FanID = lsr.FanID
						  AND lsr.EndDate IS NULL)


	/*******************************************************************************************************************************************
		3. Find Customers that are still active and assign a new percentage of customers the new OPE
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#LionSend_OPERollout') IS NOT NULL DROP TABLE #LionSend_OPERollout;
		WITH
		LionSend_OPERollout AS (SELECT FanID
									 , OnNewOPE
									 , NTILE(100) OVER (ORDER BY OnNewOPE DESC, ABS(CHECKSUM(NEWID()))) AS CustomerBin
								FROM (	SELECT FanID
											 , OnNewOPE
										FROM [Lion].[LionSend_OPERollout] lsr
										WHERE lsr.EndDate IS NULL
										AND EXISTS (SELECT 1
													FROM #Email_Base eb
													WHERE lsr.FanID = eb.FanID)) lsr)
		SELECT FanID
			 , OnNewOPE
			 , CustomerBin
			 , CASE WHEN CustomerBin <= @NewPercentageForNewOPE THEN 1 ELSE 0 END AS NewOnNewOPE
		INTO #LionSend_OPERollout
		FROM LionSend_OPERollout

	/*******************************************************************************************************************************************
		4. Store rows to update / insert
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#UpdatedRows') IS NOT NULL DROP TABLE #UpdatedRows;
		SELECT DISTINCT
			   lsr.ID
			 , lsr.FanID
			 , lsrn.NewOnNewOPE
		INTO #UpdatedRows
		FROM [Lion].[LionSend_OPERollout] lsr
		INNER JOIN #LionSend_OPERollout lsrn
			ON lsrn.FanID = lsr.FanID
			AND lsr.EndDate IS NULL
		WHERE lsr.OnNewOPE != lsrn.NewOnNewOPE

	/*******************************************************************************************************************************************
		5. Update Existing rows
	*******************************************************************************************************************************************/

		UPDATE lsr
		SET lsr.EndDate = DATEADD(DAY, -1, GETDATE())
		FROM [Lion].[LionSend_OPERollout] lsr
		WHERE EXISTS (SELECT 1
					  FROM #UpdatedRows ur
					  WHERE lsr.ID = ur.ID)

	/*******************************************************************************************************************************************
		6. Insert new rows
	*******************************************************************************************************************************************/

		INSERT INTO [Lion].[LionSend_OPERollout]
		SELECT ur.FanID
			 , ur.NewOnNewOPE
			 , GETDATE()
			 , NULL
		FROM #UpdatedRows ur
		WHERE NOT EXISTS (SELECT 1
						  FROM [Lion].[LionSend_OPERollout] lsr
						  WHERE ur.FanID = lsr.FanID
						  AND lsr.EndDate IS NULL)

	END