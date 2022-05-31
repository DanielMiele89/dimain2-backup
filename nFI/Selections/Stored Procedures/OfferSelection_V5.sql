
CREATE PROCEDURE [Selections].[OfferSelection_V5] (@OfferDate DATE
												, @PartnerID INT
												, @RunType BIT
												, @ClubID INT)
AS
BEGIN

	/*******************************************************************************************************************************************
		1. Variables to be used if testing
	*******************************************************************************************************************************************/
	
		--DECLARE @OfferDate DATE = '2021-12-02'
		--	  , @RunType CHAR(1) = 1
		--	  , @ClubID INT = 147
		--	  , @PartnerID INT = 4898

	/*******************************************************************************************************************************************
		2. Declare varibles for sProc
	*******************************************************************************************************************************************/

		DECLARE @WelcomePeriod INT = (SELECT RegisteredAtLeast FROM [Segmentation].[PartnerSettings] WHERE PartnerID = @PartnerID AND EndDate IS NULL)
			  , @OfferMembershipClosureDate DATETIME = DATEADD(second, - 1, DATEADD(day, 14, CONVERT(DATETIME, @OfferDate)))
			  , @Today DATE = GETDATE()
			  , @TodayDateTime DATETIME = GETDATE()
			  , @ClubName VARCHAR(50) = (SELECT Name FROM [SLC_Report].[dbo].[Club] WHERE ID = @ClubID)
			  , @PartnerName VARCHAR(50) = (SELECT Name FROM [SLC_Report].[dbo].[Partner] WHERE ID = @PartnerID)


	/*******************************************************************************************************************************************
		3. Fetch all offer details for partner club combination
	*******************************************************************************************************************************************/
		
		/*******************************************************************************************************************************************
			3.1. Fetch all live offers
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
				 , CASE
						WHEN cio.IronOfferID IS NOT NULL THEN 1
						ELSE 0
				   END AS BespokeOffer
			INTO #Offers
			FROM [Segmentation].[ROC_Shopper_Segment_To_Offers] sto
			INNER JOIN [SLC_REPL].[dbo].[IronOffer] iof
				ON sto.IronOfferID = iof.ID
			INNER JOIN [SLC_REPL].[dbo].[IronOfferClub] ioc
				ON iof.ID = ioc.IronOfferID
			INNER JOIN [SLC_REPL].[dbo].[Partner] pa
				ON iof.PartnerID = pa.ID
			LEFT JOIN [Selections].[CustomerInclusionsOffers] cio
				ON iof.ID = cio.IronOfferID
				AND @OfferDate >= cio.StartDate
				AND (cio.EndDate IS NULL OR cio.EndDate > @OfferDate)
			WHERE iof.PartnerID = @PartnerID
			AND iof.StartDate <= @OfferDate
			AND (iof.EndDate IS NULL OR iof.EndDate > @OfferDate)
			AND ioc.ClubID IN (@ClubID)
			AND sto.LiveOffer = 1
			AND iof.IsSignedOff = 1
			AND iof.Name NOT LIKE '%Spare%'
			AND iof.Name NOT LIKE '%Default%'

			INSERT INTO #Offers
			SELECT ioc.ClubID
				 , pa.ID AS PartnerID
				 , pa.Name AS PartnerName
				 , pts.IronOffer2nd
				 , iof.Name AS IronOfferName
				 , iof.StartDate
				 , iof.EndDate
				 , o.LiveOffer
				 , o.WelcomeOffer
				 , o.ShopperSegmentTypeID
				 , o.BespokeOffer
			FROM #Offers o
			INNER JOIN [nFI].[Selections].[Roc_Offers_Primary_to_Secondary] pts
				ON o.IronOfferID = pts.IronOfferID
			INNER JOIN [SLC_REPL].[dbo].[IronOffer] iof
				ON pts.IronOffer2nd = iof.ID
			INNER JOIN [SLC_REPL].[dbo].[IronOfferClub] ioc
				ON iof.ID = ioc.IronOfferID
			INNER JOIN [SLC_REPL].[dbo].[Partner] pa
				ON iof.PartnerID = pa.ID
			WHERE iof.PartnerID != @PartnerID
			AND iof.StartDate <= @OfferDate
			AND (iof.EndDate IS NULL OR iof.EndDate > @OfferDate)
			AND ioc.ClubID IN (@ClubID)
			AND iof.IsSignedOff = 1
			AND iof.Name NOT LIKE '%Spare%'
			AND iof.Name NOT LIKE '%Default%'


		/*******************************************************************************************************************************************
			3.2. Fetch all PartnerIDs that are running
		*******************************************************************************************************************************************/
		
			IF OBJECT_ID('tempdb..#Partners') IS NOT NULL DROP TABLE #Partners
			SELECT DISTINCT
				   PartnerID
			INTO #Partners
			FROM #Offers

		/*******************************************************************************************************************************************
			3.3. Fetch all offers ending
		*******************************************************************************************************************************************/
			
			IF OBJECT_ID('tempdb..#OffersEnding') IS NOT NULL DROP TABLE #OffersEnding
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
				 , CASE
						WHEN cio.IronOfferID IS NOT NULL THEN 1
						ELSE 0
				   END AS BespokeOffer
			INTO #OffersEnding
			FROM [Segmentation].[ROC_Shopper_Segment_To_Offers] sto
			INNER JOIN [SLC_REPL].[dbo].[IronOffer] iof
				ON sto.IronOfferID = iof.ID
			INNER JOIN [SLC_REPL].[dbo].[IronOfferClub] ioc
				ON iof.ID = ioc.IronOfferID
			INNER JOIN [SLC_REPL].[dbo].[Partner] pa
				ON iof.PartnerID = pa.ID
			LEFT JOIN [Selections].[CustomerInclusionsOffers] cio
				ON iof.ID = cio.IronOfferID
				AND @OfferDate >= cio.StartDate
				AND (cio.EndDate IS NULL OR cio.EndDate > @OfferDate)
			WHERE ioc.ClubID = @ClubID
			AND iof.PartnerID = @PartnerID
			AND iof.EndDate BETWEEN @Today AND @OfferDate
			AND iof.IsSignedOff = 1
			AND iof.Name NOT LIKE '%Spare%'
			AND iof.Name NOT LIKE '%Default%'
			
			INSERT INTO #OffersEnding
			SELECT ioc.ClubID
				 , pa.ID AS PartnerID
				 , pa.Name AS PartnerName
				 , pts.IronOffer2nd
				 , iof.Name AS IronOfferName
				 , iof.StartDate
				 , iof.EndDate
				 , o.LiveOffer
				 , o.WelcomeOffer
				 , o.ShopperSegmentTypeID
				 , o.BespokeOffer
			FROM #OffersEnding o
			INNER JOIN [nFI].[Selections].[Roc_Offers_Primary_to_Secondary] pts
				ON o.IronOfferID = pts.IronOfferID
			INNER JOIN [SLC_REPL].[dbo].[IronOffer] iof
				ON pts.IronOffer2nd = iof.ID
			INNER JOIN [SLC_REPL].[dbo].[IronOfferClub] ioc
				ON iof.ID = ioc.IronOfferID
			INNER JOIN [SLC_REPL].[dbo].[Partner] pa
				ON iof.PartnerID = pa.ID
			WHERE ioc.ClubID = @ClubID
			AND iof.PartnerID != @PartnerID
			AND iof.EndDate BETWEEN @Today AND @OfferDate
			AND iof.IsSignedOff = 1
			AND iof.Name NOT LIKE '%Spare%'
			AND iof.Name NOT LIKE '%Default%'


	/*******************************************************************************************************************************************
		4. If checking then return list of offers
	*******************************************************************************************************************************************/

		SELECT 'Offers Live' AS OfferType
			 , *
		FROM #Offers
		UNION
		SELECT 'Offers Ending' AS OfferType
			 , *
		FROM #OffersEnding

	/*******************************************************************************************************************************************
		5. Add entries to OfferMermberClosure & OfferMemberAddition
	*******************************************************************************************************************************************/

		IF @RunType = 0
			BEGIN
				RETURN
			END
		
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
					 , cu.SourceUID
					 , cu.RegistrationDate
					 , CASE
							WHEN DATEDIFF(day, cu.RegistrationDate, @OfferDate) < (28 * @WelcomePeriod) THEN 1
							ELSE 0
					   END AS WelcomeCustomer
					 , ssm.ShopperSegmentTypeID
					 , pa.PartnerID
					 , CASE
							WHEN ci.SourceUID IS NOT NULL THEN 1
							ELSE 0
					   END AS BespokeOffer
				INTO #Customers
				FROM [Relational].[Customer] cu
				CROSS JOIN #Partners pa
				LEFT JOIN [Segmentation].[ROC_Shopper_Segment_Members] ssm
					ON cu.FanID = ssm.FanID
					AND @PartnerID = ssm.PartnerID
					AND ssm.EndDate IS NULL
				LEFT JOIN [nFI].[Selections].[CustomerInclusions] ci
					ON ci.PartnerID = @PartnerID
					AND ci.ClubID = @ClubID
					AND @OfferDate >= ci.StartDate
					AND (ci.EndDate IS NULL OR ci.EndDate > @OfferDate)
					AND cu.SourceUID = ci.SourceUID
				WHERE cu.ClubID = @ClubID
				AND cu.Status = 1
				AND NOT EXISTS (SELECT 1
								FROM nFI.Selections.CustomerExclusions ce
								WHERE ce.PartnerID = @PartnerID
								AND ce.ClubID = @ClubID
								AND @OfferDate >= ce.StartDate
								AND (ce.EndDate IS NULL OR ce.EndDate > @OfferDate)
								AND cu.SourceUID = ce.SourceUID)

				IF @PartnerID = 4898
					BEGIN

						;WITH
						Offers AS (	SELECT	DISTINCT
											ShopperSegmentTypeID
									FROM #Offers)

						UPDATE cu
						SET cu.ShopperSegmentTypeID = COALESCE(iof.ShopperSegmentTypeID, 9)
						FROM #Customers cu
						LEFT JOIN Offers iof
							ON cu.ShopperSegmentTypeID = iof.ShopperSegmentTypeID

					END

				--DELETE cu
				--FROM #Customers cu
				--INNER JOIN #Offers iof
				--	ON cu.ShopperSegmentTypeID = iof.ShopperSegmentTypeID
				--WHERE EXISTS (	SELECT 1
				--				FROM [nFI].[Selections].[CustomerInclusionsOffers] cio
				--				WHERE cio.PartnerID = @PartnerID
				--				AND cio.ClubID = @ClubID
				--				AND @OfferDate >= cio.StartDate
				--				AND (cio.EndDate IS NULL OR cio.EndDate > @OfferDate)
				--				AND iof.IronOfferID = cio.IronOfferID)
				--AND NOT EXISTS (SELECT 1
				--				FROM [nFI].[Selections].[CustomerInclusions] ci
				--				WHERE ci.PartnerID = @PartnerID
				--				AND ci.ClubID = @ClubID
				--				AND @OfferDate >= ci.StartDate
				--				AND (ci.EndDate IS NULL OR ci.EndDate > @OfferDate)
				--				AND cu.SourceUID = ci.SourceUID)

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
						WHERE EXISTS (	SELECT 1
										FROM #Offers iof
										WHERE iof.WelcomeOffer = 1)
						AND NOT EXISTS (SELECT 1
										FROM #Offers iof
										WHERE iof.WelcomeOffer != 1)


					/***********************************************************************************************************************
						5.1.1.3. If there is a universal offer then update customer segment to reflect that
					***********************************************************************************************************************/
		
						UPDATE cu
						SET cu.ShopperSegmentTypeID = -1
						FROM #Customers cu
						WHERE EXISTS (	SELECT 1
										FROM #Offers iof
										WHERE iof.ShopperSegmentTypeID = -1)
						AND NOT EXISTS (SELECT 1
										FROM #Offers iof
										WHERE iof.ShopperSegmentTypeID != -1)

					/***********************************************************************************************************************
						5.1.1.4. If there is only a welcome offer then update customer segment to reflect that
					***********************************************************************************************************************/
									
						UPDATE cu
						SET cu.ShopperSegmentTypeID = 0
						FROM #Customers cu
						WHERE EXISTS (	SELECT 1
										FROM #Offers iof
										WHERE iof.WelcomeOffer = 1)
						AND NOT EXISTS (SELECT 1
										FROM #Offers iof
										WHERE iof.WelcomeOffer != 1)

			
			/***********************************************************************************************************************
				5.1.2. Fetch all existing offer memberships for customers on club already on an offer for the partner
			***********************************************************************************************************************/

				IF OBJECT_ID('tempdb..#IronOfferMember') IS NOT NULL DROP TABLE #IronOfferMember
				SELECT iom.IronOfferID
					 , iom.CompositeID
					 , iom.StartDate
					 , iom.EndDate
					 , iof.PartnerID
				INTO #IronOfferMember
				FROM [SLC_REPL].[dbo].[IronOfferMember] iom
				INNER JOIN #Offers iof
					ON iom.IronOfferID = iof.IronOfferID
				WHERE (iom.EndDate IS NULL OR iom.EndDate >= @OfferDate)
				AND EXISTS (SELECT 1
							FROM [SLC_Report].[dbo].[Fan] fa
							WHERE fa.ClubID = @ClubID
							AND fa.CompositeID = iom.CompositeID)

				CREATE CLUSTERED INDEX CIX_CompositeID ON #IronOfferMember (CompositeID)



		/*******************************************************************************************************************************************
			5.2. Fetch all customers who have changed shopper segment
		*******************************************************************************************************************************************/
	
			IF OBJECT_ID('tempdb..#CustomerChangedSegment') IS NOT NULL DROP TABLE #CustomerChangedSegment
			SELECT cu.FanID
				 , cu.CompositeID
				 , cu.RegistrationDate
				 , cu.ShopperSegmentTypeID
				 , iom.IronOfferID
				 , iom.StartDate
				 , CASE
						WHEN cu.BespokeOffer = 1 AND iof.BespokeOffer = 0 THEN DATEADD(DAY, -14, @OfferMembershipClosureDate)
						ELSE @OfferMembershipClosureDate
				   END AS EndDate
				 , iof.PartnerID
			INTO #CustomerChangedSegment
			FROM #Customers cu
			INNER JOIN #IronOfferMember iom
				ON cu.CompositeID = iom.CompositeID
				AND cu.PartnerID = iom.PartnerID
			INNER JOIN #Offers iof
				ON iom.IronOfferID = iof.IronOfferID
			WHERE cu.ShopperSegmentTypeID != iof.ShopperSegmentTypeID
			AND iof.ShopperSegmentTypeID != -1

			
				/***********************************************************************************************************************
					5.2.1 Remove table entries from Customer & IronOfferMember for all customers who have changed shopper segment
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
						AND cu.PartnerID = ccs.PartnerID
					WHERE ccs.EndDate = @OfferMembershipClosureDate


		/*******************************************************************************************************************************************
			5.3. Fetch all customers with an existsing offer membership for the segment they are currently in
		*******************************************************************************************************************************************/
	
			IF OBJECT_ID('tempdb..#AlreadyOnCorrectOffer') IS NOT NULL DROP TABLE #AlreadyOnCorrectOffer
			SELECT cu.FanID
				 , cu.CompositeID
				 , cu.RegistrationDate
				 , cu.ShopperSegmentTypeID
				 , iof.PartnerID
				 , iom.IronOfferID
				 , iof.IronOfferName
				 , iom.StartDate
				 , iom.EndDate
			INTO #AlreadyOnCorrectOffer
			FROM #Customers cu
			INNER JOIN #Offers iof
				ON (cu.ShopperSegmentTypeID = iof.ShopperSegmentTypeID OR iof.ShopperSegmentTypeID = -1)
				AND cu.PartnerID = iof.PartnerID
				AND cu.BespokeOffer = iof.BespokeOffer
			INNER JOIN #IronOfferMember iom
				ON cu.CompositeID = iom.CompositeID
				AND iof.IronOfferID = iom.IronOfferID


				/***********************************************************************************************************************
					5.3.1 Remove table entries from Customer & IronOfferMember for all correctly assigned members
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
						AND cu.PartnerID = aoco.PartnerID
						

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
				 , @TodayDateTime AS [Date]
				 , 0 AS IsControl
				 , iof.PartnerID
			INTO #CustomersToAdd
			FROM #Customers cu
			INNER JOIN #Offers iof
				ON cu.ShopperSegmentTypeID = iof.ShopperSegmentTypeID
				AND cu.PartnerID = iof.PartnerID
				AND cu.BespokeOffer = iof.BespokeOffer
			
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
						AND cu.PartnerID = cta.PartnerID


		/*******************************************************************************************************************************************
			5.6. Add all remaining customers to Universal offers if required
		*******************************************************************************************************************************************/
	
			IF OBJECT_ID('tempdb..#CustomersToAdd_Universal') IS NOT NULL DROP TABLE #CustomersToAdd_Universal
			SELECT cu.FanID
				 , cu.CompositeID
				 , cu.RegistrationDate
				 , iof.IronOfferID
				 , @OfferDate AS StartDate
				 , NULL AS EndDate
				 , @TodayDateTime AS [Date]
				 , 0 AS IsControl
				 , iof.PartnerID
			INTO #CustomersToAdd_Universal
			FROM #Customers cu
			INNER JOIN #Offers iof
				ON cu.PartnerID = iof.PartnerID
			WHERE iof.ShopperSegmentTypeID = -1


				/***********************************************************************************************************************
					5.5.1 Remove table entries from Customer & IronOfferMember for all customers who need to be placed on an offer
				***********************************************************************************************************************/

					DELETE iom
					FROM #IronOfferMember iom
					INNER JOIN #CustomersToAdd_Universal cta
						ON iom.CompositeID = cta.CompositeID
						AND iom.IronOfferID = cta.IronOfferID

					DELETE cu
					FROM #Customers cu
					INNER JOIN #CustomersToAdd_Universal cta
						ON cu.CompositeID = cta.CompositeID
						AND cu.PartnerID = cta.PartnerID


		/*******************************************************************************************************************************************
			5.7. Fetch all memberships of offers set to end
		*******************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#IronOfferMemberEnding') IS NOT NULL DROP TABLE #IronOfferMemberEnding
			SELECT iom.IronOfferID
				 , iom.CompositeID
				 , iom.StartDate
				 , iof.EndDate
			INTO #IronOfferMemberEnding
			FROM [SLC_REPL].[dbo].[IronOfferMember] iom
			INNER JOIN #OffersEnding iof
				ON iom.IronOfferID = iof.IronOfferID
			WHERE iom.EndDate IS NULL
			
			CREATE CLUSTERED INDEX CIX_CompositeID ON #IronOfferMemberEnding (CompositeID)


		/*******************************************************************************************************************************************
			5.8. Add offers that require ending to OfferMemberClosure
		*******************************************************************************************************************************************/
	

				/***********************************************************************************************************************
					5.8.1 Customers who have changed segment
				***********************************************************************************************************************/
			
					INSERT INTO [Warehouse].[iron].[OfferMemberClosure] (IronOfferID
																	   , CompositeID
																	   , StartDate
																	   , EndDate)
					SELECT	DISTINCT
							IronOfferID
						,	CompositeID
						,	StartDate
						,	EndDate
					FROM #CustomerChangedSegment
			
				/***********************************************************************************************************************
					5.8.2 Customers who have deactivated
				***********************************************************************************************************************/
			
					INSERT INTO [Warehouse].[iron].[OfferMemberClosure] (IronOfferID
																	   , CompositeID
																	   , StartDate
																	   , EndDate)
					SELECT	DISTINCT
							IronOfferID
						,	CompositeID
						,	StartDate
						,	EndDate
					FROM #CustomerDeactivated cd
					WHERE NOT EXISTS (	SELECT 1
										FROM [Warehouse].[iron].[OfferMemberClosure] omc
										WHERE cd.IronOfferID = omc.IronOfferID
										AND cd.CompositeID = omc.CompositeID)
			
				/***********************************************************************************************************************
					5.8.3 Offers that are ending
				***********************************************************************************************************************/
			
					INSERT INTO [Warehouse].[iron].[OfferMemberClosure] (IronOfferID
																	   , CompositeID
																	   , StartDate
																	   , EndDate)
					SELECT	DISTINCT
							IronOfferID
						,	CompositeID
						,	StartDate
						,	EndDate
					FROM #IronOfferMemberEnding iom
					WHERE NOT EXISTS (	SELECT 1
										FROM [Warehouse].[iron].[OfferMemberClosure] omc
										WHERE iom.IronOfferID = omc.IronOfferID
										AND iom.CompositeID = omc.CompositeID)


		/*******************************************************************************************************************************************
			5.9. Add new memberships to OfferMemberAddition
		*******************************************************************************************************************************************/
	
			INSERT INTO [Warehouse].[iron].[OfferMemberAddition]
			SELECT	CompositeID
				,	IronOfferID
				,	StartDate
				,	EndDate
				,	[Date]
				,	IsControl
			FROM #CustomersToAdd

			INSERT INTO [Warehouse].[iron].[OfferMemberAddition]
			SELECT	CompositeID
				,	IronOfferID
				,	StartDate
				,	EndDate
				,	[Date]
				,	IsControl
			FROM #CustomersToAdd_Universal


	/*******************************************************************************************************************************************
		6. Check counts of entries added
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#OffersToCount') IS NOT NULL DROP TABLE #OffersToCount
		SELECT PartnerName
			 , IronOfferID
		INTO #OffersToCount
		FROM #Offers
		UNION
		SELECT PartnerName
			 , IronOfferID
		FROM #OffersEnding		
		
		CREATE CLUSTERED INDEX CIX_CompositeID ON #OffersToCount (IronOfferID)

	/*******************************************************************************************************************************************
		7. Check counts of entries added
	*******************************************************************************************************************************************/

		SELECT @ClubName AS ClubName
			 , PartnerName
			 , SUM(CASE WHEN [Type] = 'Additions' THEN Customers END) AS Additions
			 , SUM(CASE WHEN [Type] = 'EndDates' THEN Customers END) AS EndDates
		FROM (SELECT 'EndDates' AS [Type]
			  	   , PartnerName
			  	   , COUNT(*) AS Customers
			  FROM [Warehouse].[iron].[OfferMemberClosure] omc
			  INNER JOIN #OffersToCount otc
				ON omc.IronOfferID = otc.IronOfferID
			  GROUP BY PartnerName
			  UNION
			  SELECT 'Additions' AS [Type]
			  	   , PartnerName
			  	   , COUNT(*) AS Customers
			  FROM [Warehouse].[iron].[OfferMemberAddition] oma
			  INNER JOIN #OffersToCount otc
				ON oma.IronOfferID = otc.IronOfferID
			  GROUP BY PartnerName) cc
		GROUP BY PartnerName

END