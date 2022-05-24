/****** Script for SelectTopNRows command from SSMS  ******/

CREATE PROCEDURE [Staging].[SSRS_R0201_OPE_Creation] (@EmailDate DATE
												   , @ForcedInOfferIDs VARCHAR(100) = NULL) 

AS 
BEGIN

	--DECLARE	@EmailDate DATE = '2021-01-28'
	--	,	@ForcedInOfferIDs VARCHAR(100) = NULL

	IF OBJECT_ID('tempdb..#PartnersToExclude') IS NOT NULL DROP TABLE #PartnersToExclude
	SELECT	pa.ID AS PartnerID
		,	pa.Name AS PartnerName
	INTO #PartnersToExclude
	FROM [SLC_REPL].[dbo].[Partner] pa
	INNER JOIN [Selections].[OPE_PartnerExclusions] pe
		ON pa.ID = pe.PartnerID
		AND @EmailDate BETWEEN pe.StartDate AND COALESCE(pe.EndDate, '9999-12-31')

	CREATE CLUSTERED INDEX CIX_PartnerID ON #PartnersToExclude (PartnerID)


/*******************************************************************************************************************************************
	2. Find the top cashback rate per offer
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#TopCashbackRate') IS NOT NULL DROP TABLE #TopCashbackRate
	SELECT RequiredIronOfferID
		 , Max(CommissionRate) AS TCBR
	INTO #TopCashbackRate
	FROM [SLC_REPL].[dbo].[PartnerCommissionRule]
	WHERE Status = 1
	AND TypeID = 1
	GROUP BY RequiredIronOfferID

/*******************************************************************************************************************************************
	3. Find all live offers
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#LiveOffers') IS NOT NULL DROP TABLE  #LiveOffers
	SELECT DISTINCT
		   i.ID AS IronOfferID
		 , CASE
				WHEN Name LIKE '%-%' AND i.ID != 19887 AND Name NOT LIKE '%-[0-9]%' THEN REPLACE(Name, '-', '/')
				ELSE Name
		   END AS [IronOfferName]
		 , I.[StartDate]
		 , I.[EndDate]
		 , I.[PartnerID]
		 , COALESCE(tcb.TCBR, '') AS [TopCashBackRate]
		 , CASE
				WHEN POB.OfferID IS NOT NULL THEN 1
				ELSE 0
		   END AS IsBaseOffer
		 , CASE
				WHEN @ForcedInOfferIDs LIKE '%' + CONVERT(VARCHAR(10), i.ID) + '%' THEN 1
				ELSE 0
		   END AS IsForcedInOfferIDs
	INTO #LiveOffers
	FROM [SLC_REPL].[dbo].[IronOffer] I
	INNER JOIN [SLC_REPL].[dbo].[IronOfferClub] ioc
		ON i.ID = ioc.IronOfferID
	LEFT JOIN #TopCashbackRate tcb
		ON i.ID = tcb.RequiredIronOfferID
	LEFT JOIN [Relational].[PartnerOffers_Base]  POB
		ON i.ID = OfferID
	WHERE ioc.ClubID IN (132, 138)
	AND (I.EndDate > @EmailDate OR I.EndDate IS NULL) 
	AND i.StartDate <= @EmailDate
	AND i.IsDefaultCollateral = 0 
	AND i.IsAboveTheLine = 0 
	AND Name <> 'suppressed'
	AND Name NOT LIKE 'Spare%'
	AND i.IsTriggerOffer = 0
	AND NOT EXISTS (SELECT 1
					FROM #PartnersToExclude pte
					WHERE i.PartnerID = pte.PartnerID)
	AND i.ID NOT IN (315,371,372,373,379,380,381,382,383,384,385,386,387,388,389,390,391,392,393,394,395,396,397,398,399,400,401,402,403,404,405,406,407,408,409,410,426,427,428,429,430,431,432,433,434,435,436,437,438,439,440,441,442,443,444,445,446,447,448,449,450,451,452,453,454,455,456,457,458,459,460,515,528,539,554,564,575,584,586,589,590,594,610,614,615,799,800,801,802,803,1117,1590,1746,1748,1756,1758,1760,1761,1764,1768,1772,1776,1778,1782,1786,1788,1790,1791,1793,1847,6872,6876,9608,9609,9702,11645,11646,18287,18288,18289,18290,18291,18292,18293,18294,18295,18296,18297,18298,18299,18300)
	AND NOT (i.IsSignedOff = 0 AND i.StartDate < @EmailDate)


/*******************************************************************************************************************************************
	2. Find all live offers
*******************************************************************************************************************************************/

IF OBJECT_ID('tempdb..#MinStartDate') IS NOT NULL DROP TABLE #MinStartDate
SELECT [PartnerID]
	  ,min(StartDate) as 'MinStartDate'
	  into #MinStartDate
FROM [SLC_REPL].[dbo].[IronOffer]

where IsDefaultCollateral = 0 
and IsAboveTheLine = 0 
and Name not like 'Spare%'

group by [PartnerID]
order by MinStartDate


----- Ordering

IF OBJECT_ID('tempdb..#OfferPrePriority') IS NOT NULL DROP TABLE #OfferPrePriority

SELECT  LO.*
	   ,case when IronOfferName like '%welcome%' or IronOfferName like '%Birthday%' or IronOfferName like '%Homemover%' then 1
	    else 0 end as 'IsWel/Home/BirthOffer'
	   ,case when lo.PartnerID IN (4263, 4265, 4743) then 1
	    else 0 end as 'IsPlatinumRetailers'
	   ,case when MSD.PartnerID is not null then 1 
	    else 0 end as 'IsRetailerLaunch'
	   ,case when StartDate = @EmailDate then 1
	    else 0 end as 'IsNewOffer'

into #OfferPrePriority
From #LiveOffers LO
LEFT JOIN #MinStartDate MSD on MSD.PartnerID = LO.PartnerID and  @EmailDate = MinStartDate


----- Ranking

IF OBJECT_ID('tempdb..#OfferPostPriority') IS NOT NULL DROP TABLE #OfferPostPriority
Select  [PartnerName]
	   ,[AccountManager]
       ,[IronOfferID]	
	   ,[IronOfferName]		
	   ,[TopCashBackRate]
	   ,convert(date,[EndDate]) as 'EndDate'
	   ,convert(date,[StartDate]) as 'StartDate'
	   ,[IsNewOffer]
	   ,Case When IsBaseOffer = 1 Then 'Core Base' Else '' End as BaseOffer
	   ,ROW_NUMBER() over (order by [IsForcedInOfferIds]desc,[IsBaseOffer],[IsRetailerLaunch]desc,[IsPlatinumRetailers]desc,[IsWel/Home/BirthOffer]desc,[topcashbackrate]desc, [startdate]) as 'Rank'
Into #OfferPostPriority
From #OfferPrePriority OP
Join [Relational].[Partner] P on OP.PartnerID = P.PartnerID 

IF OBJECT_ID('tempdb..#NameSplit') IS NOT NULL DROP TABLE #NameSplit
SELECT *
INTO #NameSplit
FROM (
Select [PartnerName]
       ,[AccountManager]
	   ,[Item]
       ,[IronOfferID]   
       ,[TopCashBackRate]
       ,[StartDate]
       ,[EndDate]
       ,[IsNewOffer]
       ,[BaseOffer]
       ,[IronOfferName]       
       ,[Rank]
	   ,RANK() OVER (PARTITION BY [IronOfferID] ORDER BY ItemNumber DESC) AS ItemNumberRev
	   ,COUNT(*) OVER (PARTITION BY [IronOfferID]) AS NameSplits
	   ,CASE WHEN Item LIKE '[A-Z][A-Z]%[0-9][0-9][0-9]' THEN 1 ELSE 0 END AS IsClientServiceRef
From #OfferPostPriority
Cross Apply dbo.il_SplitDelimitedStringArray ((Ironoffername), '/')) a

Select [PartnerName]
       ,[AccountManager]
	   , Coalesce(Max(ClientServicesRef), '') as ClientServicesRef
	   , Coalesce(Max(CampaignType), '') as CampaignType
	   , Coalesce(Max(OfferName), '') as OfferName
       ,[IronOfferID]   
       ,[TopCashBackRate]
       ,[BaseOffer]
       ,[EndDate]
       ,[IsNewOffer]
 --      ,[IronOfferName]       
       ,[Rank]
From (
Select [PartnerName]
       ,[AccountManager]
	 , CASE
			WHEN IsClientServiceRef = 1 THEN Item
			ELSE ''
	   END AS ClientServicesRef
	 , CASE
			WHEN StartDate > '2019-06-10' AND NameSplits > 2 AND ItemNumberRev = 2 THEN Item
			WHEN StartDate < '2019-06-10' AND NameSplits > 4 AND ItemNumberRev = 2 THEN Item
			ELSE ''
	   END AS CampaignType
	 , CASE
			WHEN ItemNumberRev = 1 THEN Item
			ELSE ''
	   END AS OfferName
       ,[IronOfferID]   
       ,[TopCashBackRate]
       ,[EndDate]
       ,[IsNewOffer]
       ,[BaseOffer]
       ,[IronOfferName]       
       ,[Rank]
FROM #NameSplit) opp
Group by [PartnerName]
       ,[AccountManager]
       ,[IronOfferID]   
       ,[IronOfferName]       
       ,[TopCashBackRate]
       ,[EndDate]
       ,[IsNewOffer]
       ,[BaseOffer]
       ,[Rank]
Order by [Rank]

END