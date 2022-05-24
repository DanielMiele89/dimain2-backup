CREATE PROCEDURE [Staging].[SSRS_R0182_OffersEndingReport](@FromDate Date
														, @ToDate Date)
									
AS

Begin

--Declare @FromDate Date = '2020-03-16'
--	  , @ToDate Date = '2020-04-16'


IF OBJECT_ID ('tempdb..#OfferDetails') IS NOT NULL DROP TABLE #OfferDetails
SELECT MAX(COALESCE(par1.AccountManager, par2.AccountManager)) AS AccountManager
	 , pa.Name AS Retailer
	 , pa.ID AS PartnerID
	 , CASE
			WHEN cl.Name IN ('NatWest MyRewards', 'RBS MyRewards') THEN 'MyRewards'
			ELSE COALESCE(ncl.ClubName, cl.Name)
	   END AS Publisher
	 , COALESCE(wh.ClientServicesRef, nh.ClientServicesRef, '') AS ClientServicesRef
	 , iof.ID AS OfferID
	 , iof.Name AS OfferName
	 , CONVERT(DATE, iof.StartDate) AS StartDate
	 , CONVERT(DATE, iof.EndDate) AS EndDate
INTO #OfferDetails
FROM [SLC_Report].[dbo].[IronOffer] iof
INNER JOIN [SLC_Report].[dbo].[IronOfferClub] ioc
	ON iof.ID = ioc.IronOfferID
LEFT JOIN [nFI].[Relational].[Club] ncl
	ON ioc.ClubID = ncl.ClubID
INNER JOIN [SLC_Report].[dbo].[Club] cl
	ON ioc.ClubID = cl.ID
INNER JOIN [SLC_Report].[dbo].[Partner] pa
	ON iof.PartnerID = pa.ID
LEFT JOIN [Warehouse].[Relational].[IronOffer_Campaign_HTM] wh
	ON iof.ID = wh.IronOfferID
LEFT JOIN [nFI].[Relational].[IronOffer_Campaign_HTM] nh
	ON iof.ID = nh.IronOfferID
LEFT JOIN iron.PrimaryRetailerIdentification pri
	ON pa.ID = pri.PartnerID
	OR pa.ID = pri.PrimaryPartnerID
LEFT JOIN Relational.Partner par1
	ON par1.PartnerID = COALESCE(pri.PartnerID, pri.PrimaryPartnerID)
LEFT JOIN Relational.Partner par2
	ON par2.PartnerID = COALESCE(pri.PrimaryPartnerID, pri.PartnerID)
WHERE CONVERT(DATE, iof.EndDate) BETWEEN @FromDate AND @ToDate
GROUP BY pa.Name
	   , pa.ID
	   , CASE
			WHEN cl.Name IN ('NatWest MyRewards', 'RBS MyRewards') THEN 'MyRewards'
			ELSE COALESCE(ncl.ClubName, cl.Name)
	     END
	   , COALESCE(wh.ClientServicesRef, nh.ClientServicesRef, '')
	   , iof.ID
	   , iof.Name
	   , CONVERT(DATE, iof.StartDate)
	   , CONVERT(DATE, iof.EndDate)

IF OBJECT_ID ('tempdb..#SSRSReportColoursHasSecondary') IS NOT NULL DROP TABLE #SSRSReportColoursHasSecondary
Select *, ROW_NUMBER() Over (Order by ID) as RowNo
Into #SSRSReportColoursHasSecondary
From warehouse.apw.ColourList
Where ID in (1,2,3,4,5,6,7,100,200,25,50)	

IF OBJECT_ID ('tempdb..#SSRSReportColoursSecondary') IS NOT NULL DROP TABLE #SSRSReportColoursSecondary
Select cl.ColourHexCode, cls.ColourHexCode as SecondaryColourHexCode, ColourGroupID
Into #SSRSReportColoursSecondary
From Warehouse.apw.colourlist cl
Inner join Warehouse.apw.colourlistsecondary cls on
	cl.id=cls.colourlistID

-----------------------------------------------------------------------------------------------------------------------------------------------
------------------Create table of Account Managers for each partner and place them into temp table #AccountManagerPostDedupe-------------------
-----------------------------------------------------------------------------------------------------------------------------------------------
	
	IF OBJECT_ID ('tempdb..#AccountManager') IS NOT NULL DROP TABLE #AccountManager
	SELECT DISTINCT
		   Retailer
		 , COALESCE(AccountManager, ' Unknown Account Manager ') AS AccountManager
		 , NULL AS AccountManagerRowNo
	INTO #AccountManager
	FROM #OfferDetails

	UPDATE am1
	SET am1.AccountManagerRowNo = am2.[AccountManagerRowNo]
	FROM #AccountManager AS am1
	INNER JOIN (Select Distinct AccountManager, DENSE_RANK() Over (Order by AccountManager) % 2 as AccountManagerRowNo
				From #AccountManager) AS am2
	ON am1.AccountManager = am2.[AccountManager]

-----------------------------------------------------------------------------------------------------------------------------------------------
------------------Find all ending offers on both MyRewards & nFIs, merge with Account Managers temp table created previously-------------------
-----------------------------------------------------------------------------------------------------------------------------------------------

	IF OBJECT_ID ('tempdb..#AccountColours') IS NOT NULL DROP TABLE #AccountColours
	Select a.AccountManager, am.Retailer, col.ColourHexCode, col.ID as ColourListID
	Into #AccountColours
	From (
			select Distinct AccountManagerRowNo+1 as AccountManagerRowNo, AccountManager
			from #AccountManager ) a
	Inner Join #SSRSReportColoursHasSecondary col on
		a.AccountManagerRowNo=col.RowNo
	Inner join #AccountManager am on
		a.AccountManager=am.AccountManager

	IF OBJECT_ID ('tempdb..#PrePublisherColour') IS NOT NULL DROP TABLE #PrePublisherColour
	Select *,
			case 
				when (DENSE_RANK() OVER(ORDER BY AccountManager, Retailer) ) % 2=0 then 2
				else 1
			end as RetailerColourGroup,
			case 
				when (DENSE_RANK() OVER(ORDER BY AccountManager, Retailer, Publisher) ) % 2=0 then '#7a7a7a'
				else '#5c5c5c'
			end as PublisheColourHexCode
	Into #PrePublisherColour
	From (SELECT od.*
			   , am.ColourHexCode as AccountManagerColourHexCode
		  FROM #OfferDetails od
		  LEFT JOIN #AccountColours am
			  ON LOWER(od.Retailer) = LOWER(am.Retailer)) a
	Order by AccountManager, Retailer, Publisher, OfferID
	
	Select Distinct
			AccountManager,
			Publisher,
			Retailer,
			ClientServicesRef,
			OfferID,
			OfferName,
			StartDate,
			EndDate,
			AccountManagerColourHexCode,
			cols.SecondaryColourHexCode as RetailerColourHexCode,
			PublisheColourHexCode
	from #PrePublisherColour ppc
	left join #SSRSReportColoursSecondary cols on
			ppc.AccountManagerColourHexCode=cols.ColourHexCode
		and	ppc.RetailerColourGroup=cols.ColourGroupID

End




