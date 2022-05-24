

CREATE PROCEDURE [Staging].[SSRS_R0149_nFICustomersvsCustomersonOffers_V3]
AS
BEGIN

/********************************************************************************************
** Name: R_0149 - nFI Scheme Customers vs Customers on Offers
** Desc: Returns the number of customers on a publisher  vs the number of customers on offers 
**		 broken down by retailer
** Auth: Zoe Taylor
** Date: 01/02/2017
*********************************************************************************************
** Change History
** ---------------------
** #No		Date		Author			Description 
** --		--------	-------			------------------------------------
** 1		2017-03-10	Stuart Barnley	Amendment to not include those who registered today 
										as we do not always have corresponding IOM entries 
										until the following day.

										Also replace all getdate() calls in WHERE clauses with
										@Today

** 2		2017-03-10	Stuart Barnley	Create Change so that Programmes are displaying if the
										offer is live but it has no members (VAA Collinson)

** 3		2017-03-10	Stuart Barnley	Changed to allow any date to be used for assessment, 
										this enables the ability to see yet to launch offers

** 4		2017-10-25  Stuart Barnley  Change to show Quidco as Quidco now using standard 
										segmentation
*********************************************************************************************/

	SET NOCOUNT ON

	DECLARE @Today DATE = DATEADD(DAY, -7, GETDATE())
	DECLARE @Date DATE = (	SELECT MIN(StartDate)
							FROM (	SELECT    StartDate
									FROM [Relational].[ROC_CycleDates]
									UNION ALL
									SELECT    DATEADD(DAY, 14, StartDate)
									FROM [Relational].[ROC_CycleDates]) cd
							WHERE @Today < StartDate)


		  
	--DECLARE @Today DATE = GETDATE()
	--	  , @Date DATE = '2019-10-10'
	--	  , @IType  INT = 1


-- ***********************************************************************************************
-- **			 Gets the current live offers - excludes quidco and base offers					**
-- ***********************************************************************************************

	IF OBJECT_ID('tempdb..#CurrentIronOffers') IS NOT NULL DROP TABLE #CurrentIronOffers 
	SELECT DISTINCT 
		   ioc.ClubID
		 , iof.PartnerID
		 , iof.ID AS IronOfferID
		 , iof.Name AS IronOfferName
		 , iof.StartDate
		 , iof.EndDate
	INTO #CurrentIronOffers
	FROM [SLC_REPL].[dbo].[IronOffer] iof
	INNER JOIN [SLC_REPL].[dbo].[IronOfferClub] ioc
		ON iof.ID = ioc.IronOfferID
	WHERE (iof.EndDate > @Date OR iof.EndDate IS NULL)
	AND iof.StartDate <= @Date
	AND iof.IsSignedOff = 1
	AND iof.Name NOT LIKE '%base%'
	AND iof.Name NOT LIKE '%spare%'
	AND iof.Name != '1% All Members Offer'
	AND ioc.ClubID NOT IN (132, 138, 166)

	CREATE CLUSTERED INDEX CIX_IronOfferID ON #CurrentIronOffers (IronOfferID)
	CREATE NONCLUSTERED INDEX IX_ClubID ON #CurrentIronOffers (ClubID)


	IF OBJECT_ID('tempdb..#ClubPartnerOffers') IS NOT NULL DROP TABLE #ClubPartnerOffers
	SELECT ClubID
		 , PartnerID
		 , ISNULL(AcquireOffer + ', ', '') + ISNULL(LapsedOffer + ', ', '') + ISNULL(NurseryShopperOffer + ', ', '') + ISNULL(ShopperOffer + ', ', '') + ISNULL(WelcomeOffer + ', ', '') + ISNULL(LaunchOffer + ', ', '') + ISNULL(UniversalOffer + ', ', '') AS OffersLive
	INTO #ClubPartnerOffers
	FROM (SELECT ClubID
			   , PartnerID
			   , MAX(CASE WHEN IronOfferName LIKE '%Acquire%' THEN 'Acquire' ELSE NULL END) AS AcquireOffer
			   , MAX(CASE WHEN IronOfferName LIKE '%Lapsed%' THEN 'Lapsed' ELSE NULL END) AS LapsedOffer
			   , MAX(CASE WHEN IronOfferName LIKE '%Nursery%' THEN 'NurseryShopper' ELSE NULL END) AS NurseryShopperOffer
			   , MAX(CASE WHEN IronOfferName LIKE '%Shopper%' AND IronOfferName NOT LIKE '%Nursery%' THEN 'Shopper' ELSE NULL END) AS ShopperOffer
			   , MAX(CASE WHEN IronOfferName LIKE '%Welcome%' THEN 'Welcome' ELSE NULL END) AS WelcomeOffer
			   , MAX(CASE WHEN IronOfferName LIKE '%Launch%' THEN 'Launch' ELSE NULL END) AS LaunchOffer
			   , MAX(CASE WHEN IronOfferName LIKE '%Universal%' THEN 'Universal' ELSE NULL END) AS UniversalOffer
		  FROM #CurrentIronOffers
		  GROUP BY ClubID
		  	     , PartnerID) cio

	UPDATE #ClubPartnerOffers
	SET OffersLive = LEFT(OffersLive, LEN(OffersLive) - 1)
	

-- ***********************************************************************************************
-- **			 get number of customers on the scheme by counting the fanid's in the			**
-- **						customer table and grouping by clubid 								**
-- ***********************************************************************************************


	IF OBJECT_ID('tempdb..#SchemeCustomers') IS NOT NULL DROP TABLE #SchemeCustomers;
	WITH
	QuidcoR4GCustomers AS (	SELECT fa.ID AS FanID
							FROM [SLC_REPL].[dbo].[Fan] fa
							WHERE EXISTS (SELECT 1
										  FROM [Warehouse].[InsightArchive].[QuidcoR4GCustomers] r4g
										  WHERE fa.CompositeID = r4g.CompositeID)),

	Fan AS (SELECT ClubID
				 , COUNT(DISTINCT fa.ID) AS NoOfCustomers
			FROM [SLC_REPL].[dbo].[Fan] fa
			WHERE fa.Status = 1
			--AND RegistrationDate < @Today
			GROUP BY ClubID)


	SELECT cl.Name AS ClubName
		 , cl.ID AS ClubID
		 , NoOfCustomers
	INTO #SchemeCustomers
	FROM [SLC_Repl].[dbo].[Club] cl
	LEFT JOIN Fan fa
		ON cl.ID = fa.ClubID
	WHERE EXISTS (SELECT 1
				  FROM #CurrentIronOffers cio
				  WHERE cl.ID = cio.ClubID)

	CREATE CLUSTERED INDEX CIX_ClubID ON #SchemeCustomers (ClubID)


-- ***********************************************************************************************
-- **		Looks at the current live offers and looks for members currently on the offer		**
-- ***********************************************************************************************

	IF OBJECT_ID('tempdb..#IronOfferMember') IS NOT NULL DROP TABLE #IronOfferMember 
	SELECT iom.IronOfferID
		 , iom.CompositeID
		 , iom.StartDate
		 , iom.EndDate
	INTO #IronOfferMember
	FROM #CurrentIronOffers cio
	INNER JOIN [SLC_REPL].[dbo].[IronOfferMember] iom
		ON (iom.EndDate > @Date OR iom.EndDate IS NULL)
		AND iom.StartDate <= @Date
		AND cio.IronOfferID = iom.IronOfferID
	--WHERE EXISTS (SELECT 1
	--			  FROM [SLC_REPL].[dbo].[Fan] fa
	--			  WHERE fa.Status = 1
	--			  AND RegistrationDate < @Today
	--			  AND iom.CompositeID = fa.CompositeID)

	CREATE CLUSTERED INDEX CIX_IronOfferID ON #IronOfferMember (IronOfferID)

	--IF OBJECT_ID('tempdb..#MultipleOffersPerPartner') IS NOT NULL DROP TABLE #MultipleOffersPerPartner
	--SELECT DISTINCT
	--	   ClubID
	--	 , PartnerID
	--INTO #MultipleOffersPerPartner
	--FROM (SELECT cio.ClubID
	--  		   , cio.PartnerID
	--  		   , iom.CompositeID
	--	  FROM #CurrentIronOffers cio
	--	  LEFT JOIN #IronOfferMember iom
	--  		  ON cio.IronOfferID = iom.IronOfferID
	--	  GROUP BY cio.ClubID
	--  			 , cio.PartnerID
	--  			 , iom.CompositeID
	--	  HAVING COUNT(DISTINCT iom.IronOfferID) > 1) iom


	IF OBJECT_ID('tempdb..#CustomersOnOffers') IS NOT NULL DROP TABLE #CustomersOnOffers 
	SELECT cio.ClubID
		 , cio.PartnerID
		 , COALESCE(COUNT(DISTINCT iom.CompositeID), 0) NoOfCustomers
	INTO #CustomersOnOffers
	FROM #CurrentIronOffers cio
	LEFT JOIN #IronOfferMember iom
		ON cio.IronOfferID = iom.IronOfferID
	GROUP BY cio.ClubID
		   , cio.PartnerID


-- ***********************************************************************************************
-- **		 displays values FROM both queries above to compare number of customers				**
-- **					on scheme compared to number of customers on offers						**
-- ***********************************************************************************************

	SELECT sc.ClubName
		 , sc.NoOfCustomers AS Cust_On_Scheme
		 , pa.ID AS PartnerID
		 , pa.Name AS PartnerName
		 , cpo.OffersLive
		 , SUM(co.NoOfCustomers) AS Cust_On_Offers
		 , SUM(co.NoOfCustomers) - sc.NoOfCustomers AS [differencescheme/offers]
	FROM #SchemeCustomers sc 
	LEFT JOIN #CustomersOnOffers co
		ON sc.ClubID = co.ClubID
	LEFT JOIN #ClubPartnerOffers cpo
		ON sc.ClubID = cpo.ClubID
		AND co.PartnerID = cpo.PartnerID
	LEFT JOIN [SLC_REPL]..[Partner] pa
		ON co.PartnerID = pa.ID
	GROUP BY sc.ClubName
		   , sc.NoOfCustomers
		   , pa.ID
		   , pa.Name
		   , cpo.OffersLive
	ORDER BY pa.Name
		   , sc.ClubName

END