/****** Script for SelectTopNRows command from SSMS  ******/

CREATE PROCEDURE [Report].[SSRS_V0001_OPE_Creation] (@EmailDate DATE
												   , @ForcedInOfferIDs VARCHAR(100) = NULL) 

AS 
BEGIN

	--DECLARE	@EmailDate DATE = '2021-04-07'
	--	,	@ForcedInOfferIDs VARCHAR(100) = NULL

		IF OBJECT_ID('tempdb..#PartnersToExclude') IS NOT NULL DROP TABLE #PartnersToExclude
	SELECT	pa.ID AS PartnerID
		,	pa.Name AS PartnerName
	INTO #PartnersToExclude
	FROM [SLC_REPL].[dbo].[Partner] pa
	INNER JOIN [WH_Virgin].[Email].[OPE_PartnerExclusions] pe
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
	;with LiveOffers as (
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
		 , 0 AS IsBaseOffer
		 , CASE
				WHEN @ForcedInOfferIDs LIKE '%' + CONVERT(VARCHAR(10), i.ID) + '%' THEN 1
				ELSE 0
		   END AS IsForcedInOfferIDs
	FROM [SLC_REPL].[dbo].[IronOffer] I
	INNER JOIN [SLC_REPL].[dbo].[IronOfferClub] ioc
		ON i.ID = ioc.IronOfferID
	LEFT JOIN #TopCashbackRate tcb
		ON i.ID = tcb.RequiredIronOfferID
	WHERE ioc.ClubID IN (166)
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
	AND NOT (i.IsSignedOff = 0 AND i.StartDate < @EmailDate)
	), allNonBountyOffers as (
		SELECT  *
		FROM [DIMAIN_TR].[SLC_REPL].[dbo].[PartnerCommissionRule] pcr
		WHERE CommissionRate > 0
	)
	SELECT DISTINCT L.*
	INTO #LiveOffers
	FROM LiveOffers L
	JOIN allNonBountyOffers abo
	on abo.RequiredIronOfferID = L.IronOfferID
	

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
Join [Derived].[Partner] P on OP.PartnerID = P.PartnerID 

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
Cross Apply [Warehouse].[dbo].[il_SplitDelimitedStringArray] ((Ironoffername), '/')) a

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


