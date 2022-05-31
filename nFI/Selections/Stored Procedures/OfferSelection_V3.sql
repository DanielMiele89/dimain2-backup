
CREATE PROCEDURE [Selections].[OfferSelection_V3] (@OfferDate DATE
												, @PartnerID INT
												, @RunType CHAR(1)
												, @ClubID INT)
AS
BEGIN

	/*******************************************************************************************************************************************
		1. Variables to be used if testing
	*******************************************************************************************************************************************/
	
		--DECLARE @OfferDate DATE = '2019-08-15'
		--	  , @RunType CHAR(1) = 'B'
		--	  , @ClubID INT = 145
		--	  , @PartnerID INT = 4263

	
	/*******************************************************************************************************************************************
		2. Declare varibles for sProc
	*******************************************************************************************************************************************/

		DECLARE @WelcomePeriod INT = (SELECT RegisteredAtLeast FROM [Segmentation].[PartnerSettings] WHERE PartnerID = @PartnerID)
			  , @OfferMembershipClosureDate DATETIME = DATEADD(second, - 1, DATEADD(day, 14, CONVERT(DATETIME, @OfferDate)))
			  , @Today DATE = DATEADD(day, -1, GETDATE())
			  , @ClubName VARCHAR(50) = (SELECT Name FROM [SLC_Report].[dbo].[Club] WHERE ID = @ClubID)
			  , @PartnerName VARCHAR(50) = (SELECT Name FROM [SLC_Report].[dbo].[Partner] WHERE ID = @PartnerID)


	/*******************************************************************************************************************************************
		3. Fetch all offer details for partner club combination
	*******************************************************************************************************************************************/
			
		IF OBJECT_ID('tempdb..#Offers') IS NOT NULL DROP TABLE #Offers
		SELECT ioc.ClubID
			 , pa.ID AS PartnerID
			 , pa.Name AS PartnerName
			 , sto.IronOfferID
			 , iof.Name AS IronOfferName
			 , iof.StartDate
			 , iof.EndDate
			 , sto.LiveOffer
			 , sto.WelcomeOffer
			 , sto.ShopperSegmentTypeID
		INTO #Offers
		FROM [Segmentation].[ROC_Shopper_Segment_To_Offers] sto
		INNER JOIN [SLC_REPL].[dbo].[IronOffer] iof
			ON sto.IronOfferID = iof.ID
		INNER JOIN [SLC_REPL].[dbo].[IronOfferClub] ioc
			ON iof.ID = ioc.IronOfferID
		INNER JOIN [SLC_REPL].[dbo].[Partner] pa
			ON iof.PartnerID = pa.ID
		WHERE iof.PartnerID = @PartnerID
		AND iof.StartDate <= @OfferDate
		AND (iof.EndDate IS NULL OR iof.EndDate > @OfferDate)
		AND ClubID IN (@ClubID)
		AND LiveOffer = 1
		AND iof.IsSignedOff = 1
		AND iof.Name NOT LIKE '%Spare%'
		AND iof.Name NOT LIKE '%Default%'


	/*******************************************************************************************************************************************
		4. If checking then return list of offers
	*******************************************************************************************************************************************/

		IF @RunType = 'A'
			BEGIN
				SELECT * 
				FROM #Offers

				RETURN
			END

	/*******************************************************************************************************************************************
		5. Add entries to OfferMermberClosure & OfferMemberAddition
	*******************************************************************************************************************************************/

		IF @RunType = 'B'
			BEGIN

		/*******************************************************************************************************************************************
			5.1. Fetch all customer & related offer details
		*******************************************************************************************************************************************/
			
			/***********************************************************************************************************************
				5.1.1. Fetch all customers on club and their segment for the partner, flagging customers who have joined in the last
					   2 cycles (28 days)
			***********************************************************************************************************************/
		
				IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers
				SELECT DISTINCT
					   cu.ClubID
					 , cu.FanID
					 , cu.CompositeID
					 , cu.RegistrationDate
					 , CASE
							WHEN DATEDIFF(day, cu.RegistrationDate, @OfferDate) < (28 * @WelcomePeriod) THEN 1
							ELSE 0
					   END AS WelcomeCustomer
					 , ssm.ShopperSegmentTypeID
				INTO #Customers
				FROM [Relational].[Customer] cu
				LEFT JOIN [Segmentation].[ROC_Shopper_Segment_Members] ssm
					ON cu.FanID = ssm.FanID
					AND @PartnerID = ssm.PartnerID
					AND ssm.EndDate IS NULL
				WHERE cu.ClubID = @ClubID
				AND cu.Status = 1
				AND NOT EXISTS (SELECT 1
								FROM nFI.Selections.CustomerExclusions ce
								WHERE ce.PartnerID = @PartnerID
								AND ce.ClubID = @ClubID
								AND @OfferDate >= ce.StartDate
								AND (ce.EndDate IS NULL OR ce.EndDate < @OfferDate)
								AND cu.SourceUID = ce.SourceUID)

				CREATE CLUSTERED INDEX CIX_CompositeID ON #Customers (CompositeID)
				CREATE NONCLUSTERED INDEX IX_FanID ON #Customers (FanID)

					/***********************************************************************************************************************
						5.1.1.1. If there is a welcome offer then update customer segment to reflect that
					***********************************************************************************************************************/
		
						UPDATE cu
						SET cu.ShopperSegmentTypeID = 0
						FROM #Customers cu
						WHERE cu.WelcomeCustomer = 1
						AND EXISTS (SELECT 1
									FROM #Offers iof
									WHERE iof.WelcomeOffer = 1)

					/***********************************************************************************************************************
						5.1.1.2. If there is only a welcome offer then update customer segment to reflect that
					***********************************************************************************************************************/
									
						UPDATE cu
						SET cu.ShopperSegmentTypeID = 0
						FROM #Customers cu
						WHERE EXISTS (SELECT 1
									  FROM #Offers iof
									  WHERE iof.WelcomeOffer = 1)
						AND EXISTS (SELECT 1
									FROM #Offers iof
									HAVING COUNT(*) = 1)

			
			/***********************************************************************************************************************
				5.1.2. Fetch all existing offer memberships for customers on club already on an offer for the partner
			***********************************************************************************************************************/

				IF OBJECT_ID('tempdb..#IronOfferMember') IS NOT NULL DROP TABLE #IronOfferMember
				SELECT iom.IronOfferID
					 , iom.CompositeID
					 , iom.StartDate
					 , iom.EndDate
				INTO #IronOfferMember
				FROM [SLC_REPL].[dbo].[IronOfferMember] iom
				WHERE (iom.EndDate IS NULL OR iom.EndDate >= @OfferDate)
				AND EXISTS (SELECT 1
							FROM #Offers iof
							WHERE iom.IronOfferID = iof.IronOfferID)
				AND EXISTS (SELECT 1
							FROM [SLC_Report].[dbo].[Fan] fa
							WHERE fa.ClubID = @ClubID
							AND fa.CompositeID = iom.CompositeID)

				CREATE CLUSTERED INDEX CIX_CompositeID ON #IronOfferMember (CompositeID)

		/*******************************************************************************************************************************************
			5.2. Fetch all customers with an existsing offer membership for the segment they are currently in
		*******************************************************************************************************************************************/
	
			IF OBJECT_ID('tempdb..#AlreadyOnCorrectOffer') IS NOT NULL DROP TABLE #AlreadyOnCorrectOffer
			SELECT cu.FanID
				 , cu.CompositeID
				 , cu.RegistrationDate
				 , cu.ShopperSegmentTypeID
				 , iom.IronOfferID
				 , iof.IronOfferName
				 , iom.StartDate
				 , iom.EndDate
			INTO #AlreadyOnCorrectOffer
			FROM #Customers cu
			INNER JOIN #Offers iof
				ON cu.ShopperSegmentTypeID = iof.ShopperSegmentTypeID
			INNER JOIN #IronOfferMember iom
				ON cu.CompositeID = iom.CompositeID
				AND iof.IronOfferID = iom.IronOfferID
			
				/***********************************************************************************************************************
					5.2.1 Remove table entries from Customer & IronOfferMember for all correctly assigned members
				***********************************************************************************************************************/

					DELETE iom
					FROM #IronOfferMember iom
					INNER JOIN #AlreadyOnCorrectOffer aoco
						ON iom.CompositeID = aoco.CompositeID
						AND iom.IronOfferID = aoco.IronOfferID

					DELETE cu
					FROM #Customers cu
					INNER JOIN #AlreadyOnCorrectOffer aoco
						ON cu.CompositeID = aoco.CompositeID
						AND cu.ShopperSegmentTypeID = aoco.ShopperSegmentTypeID

		/*******************************************************************************************************************************************
			5.3. Fetch all customers who have changed shopper segment
		*******************************************************************************************************************************************/
	
			IF OBJECT_ID('tempdb..#CustomerChangedSegment') IS NOT NULL DROP TABLE #CustomerChangedSegment
			SELECT cu.FanID
				 , cu.CompositeID
				 , cu.RegistrationDate
				 , cu.ShopperSegmentTypeID
				 , iom.IronOfferID
				 , iom.StartDate
				 , @OfferMembershipClosureDate AS EndDate
			INTO #CustomerChangedSegment
			FROM #Customers cu
			INNER JOIN #IronOfferMember iom
				ON cu.CompositeID = iom.CompositeID
			WHERE NOT EXISTS (SELECT 1
							  FROM #Offers iof
							  WHERE cu.ShopperSegmentTypeID = iof.ShopperSegmentTypeID
							  AND iom.IronOfferID = iof.IronOfferID)

			
				/***********************************************************************************************************************
					5.3.1 Remove table entries from Customer & IronOfferMember for all customers who have changed shopper segment
				***********************************************************************************************************************/

					DELETE iom
					FROM #IronOfferMember iom
					INNER JOIN #CustomerChangedSegment ccs
						ON iom.CompositeID = ccs.CompositeID
						AND iom.IronOfferID = ccs.IronOfferID

					DELETE cu
					FROM #Customers cu
					INNER JOIN #CustomerChangedSegment ccs
						ON cu.CompositeID = ccs.CompositeID
						AND cu.ShopperSegmentTypeID = ccs.ShopperSegmentTypeID

		/*******************************************************************************************************************************************
			5.4. Fetch all customers who have deactivated
		*******************************************************************************************************************************************/
	
			IF OBJECT_ID('tempdb..#CustomerDeactivated') IS NOT NULL DROP TABLE #CustomerDeactivated
			SELECT fa.ID AS FanID
				 , fa.CompositeID
				 , fa.RegistrationDate
				 , iom.IronOfferID
				 , iom.StartDate
				 , @OfferMembershipClosureDate AS EndDate
			INTO #CustomerDeactivated
			FROM #IronOfferMember iom
			INNER JOIN [SLC_Report].[dbo].[Fan] fa
				ON iom.CompositeID = fa.CompositeID
				AND fa.ClubID = @ClubID
				AND fa.Status = 0
			
				/***********************************************************************************************************************
					5.4.1 Remove table entries from Customer & IronOfferMember for all customers who have deactivated
				***********************************************************************************************************************/

					DELETE iom
					FROM #IronOfferMember iom
					INNER JOIN #CustomerDeactivated cd
						ON iom.CompositeID = cd.CompositeID
						AND iom.IronOfferID = cd.IronOfferID

					DELETE cu
					FROM #Customers cu
					INNER JOIN #CustomerDeactivated cd
						ON cu.CompositeID = cd.CompositeID


		/*******************************************************************************************************************************************
			5.5. Fetch all customers who need to be placed onto an offer
		*******************************************************************************************************************************************/
	
			IF OBJECT_ID('tempdb..#CustomersToAdd') IS NOT NULL DROP TABLE #CustomersToAdd
			SELECT cu.FanID
				 , cu.CompositeID
				 , cu.RegistrationDate
				 , iof.IronOfferID
				 , @OfferDate AS StartDate
				 , NULL AS EndDate
				 , GETDATE() AS [Date]
				 , 0 AS IsControl
			INTO #CustomersToAdd
			FROM #Customers cu
			INNER JOIN #Offers iof
				ON cu.ShopperSegmentTypeID = iof.ShopperSegmentTypeID
			
				/***********************************************************************************************************************
					5.5.1 Remove table entries from Customer & IronOfferMember for all customers who need to be placed on an offer
				***********************************************************************************************************************/

					DELETE iom
					FROM #IronOfferMember iom
					INNER JOIN #CustomersToAdd cta
						ON iom.CompositeID = cta.CompositeID
						AND iom.IronOfferID = cta.IronOfferID

					DELETE cu
					FROM #Customers cu
					INNER JOIN #CustomersToAdd cta
						ON cu.CompositeID = cta.CompositeID


		/*******************************************************************************************************************************************
			5.6. Add offers that require ending to OfferMemberClosure
		*******************************************************************************************************************************************/
			
				/***********************************************************************************************************************
					5.6.1 Customers who have changed segment
				***********************************************************************************************************************/
			
					INSERT INTO [Warehouse].[iron].[OfferMemberClosure] (IronOfferID
																	   , CompositeID
																	   , StartDate
																	   , EndDate)
					SELECT IronOfferID
						 , CompositeID
						 , StartDate
						 , EndDate
					FROM #CustomerChangedSegment
			
				/***********************************************************************************************************************
					5.6.2 Customers who have deactivated
				***********************************************************************************************************************/
			
					INSERT INTO [Warehouse].[iron].[OfferMemberClosure] (IronOfferID
																	   , CompositeID
																	   , StartDate
																	   , EndDate)
					SELECT IronOfferID
						 , CompositeID
						 , StartDate
						 , EndDate
					FROM #CustomerDeactivated


		/*******************************************************************************************************************************************
			5.7. Add new memberships to OfferMemberAddition
		*******************************************************************************************************************************************/
	
			INSERT INTO [Warehouse].[iron].[OfferMemberAddition]
			SELECT CompositeID
				 , IronOfferID
				 , StartDate
				 , EndDate
				 , [Date]
				 , IsControl
			 FROM #CustomersToAdd

	/*******************************************************************************************************************************************
		6. Check counts of entries added
	*******************************************************************************************************************************************/

		SELECT @ClubName AS ClubName
			 , @PartnerName AS PartnerName
			 , SUM(CASE WHEN [Type] = 'Additions' THEN Customers END) AS Additions
			 , SUM(CASE WHEN [Type] = 'EndDates' THEN Customers END) AS EndDates
		FROM (SELECT 'EndDates' AS [Type]
			  	   , IronOfferID
			  	   , COUNT(*) AS Customers
			  FROM #CustomerChangedSegment
			  GROUP BY IronOfferID
			  UNION
			  SELECT 'EndDates' AS [Type]
			  	   , IronOfferID
			  	   , COUNT(*) AS Customers
			  FROM #CustomerDeactivated
			  GROUP BY IronOfferID
			  UNION
			  SELECT 'Additions' AS [Type]
			  	   , IronOfferID
			  	   , COUNT(*) AS Customers
			  FROM #CustomersToAdd
			  GROUP BY IronOfferID) cc

	END	--	5. IF @RunType = 'B'


END