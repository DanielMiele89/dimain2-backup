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
	SELECT [SLC_REPL].[dbo].[PartnerCommissionRule].[RequiredIronOfferID]
		 , Max([SLC_REPL].[dbo].[PartnerCommissionRule].[CommissionRate]) AS TCBR
	INTO #TopCashbackRate
	FROM [SLC_REPL].[dbo].[PartnerCommissionRule]
	WHERE [SLC_REPL].[dbo].[PartnerCommissionRule].[Status] = 1
	AND [SLC_REPL].[dbo].[PartnerCommissionRule].[TypeID] = 1
	GROUP BY [SLC_REPL].[dbo].[PartnerCommissionRule].[RequiredIronOfferID]

/*******************************************************************************************************************************************
	3. Find all live offers
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#LiveOffers') IS NOT NULL DROP TABLE  #LiveOffers
	;with LiveOffers as (
	SELECT DISTINCT
		   #TopCashbackRate.[i].ID AS IronOfferID
		 , CASE
				WHEN #TopCashbackRate.[Name] LIKE '%-%' AND #TopCashbackRate.[i].ID != 19887 AND #TopCashbackRate.[Name] NOT LIKE '%-[0-9]%' THEN REPLACE(#TopCashbackRate.[Name], '-', '/')
				ELSE #TopCashbackRate.[Name]
		   END AS [IronOfferName]
		 , #TopCashbackRate.[I].[StartDate]
		 , #TopCashbackRate.[I].[EndDate]
		 , #TopCashbackRate.[I].[PartnerID]
		 , COALESCE(tcb.TCBR, '') AS [TopCashBackRate]
		 , 0 AS IsBaseOffer
		 , CASE
				WHEN @ForcedInOfferIDs LIKE '%' + CONVERT(VARCHAR(10), #TopCashbackRate.[i].ID) + '%' THEN 1
				ELSE 0
		   END AS IsForcedInOfferIDs
	FROM [SLC_REPL].[dbo].[IronOffer] I
	INNER JOIN [SLC_REPL].[dbo].[IronOfferClub] ioc
		ON i.ID = ioc.IronOfferID
	LEFT JOIN #TopCashbackRate tcb
		ON #TopCashbackRate.[i].ID = tcb.RequiredIronOfferID
	WHERE #TopCashbackRate.[ioc].ClubID IN (166)
	AND (#TopCashbackRate.[I].EndDate > @EmailDate OR #TopCashbackRate.[I].EndDate IS NULL) 
	AND #TopCashbackRate.[i].StartDate <= @EmailDate
	AND #TopCashbackRate.[i].IsDefaultCollateral = 0 
	AND #TopCashbackRate.[i].IsAboveTheLine = 0 
	AND #TopCashbackRate.[Name] <> 'suppressed'
	AND #TopCashbackRate.[Name] NOT LIKE 'Spare%'
	AND #TopCashbackRate.[i].IsTriggerOffer = 0
	AND NOT EXISTS (SELECT 1
					FROM #PartnersToExclude pte
					WHERE #PartnersToExclude.[i].PartnerID = pte.PartnerID)
	AND NOT (#TopCashbackRate.[i].IsSignedOff = 0 AND #TopCashbackRate.[i].StartDate < @EmailDate)
	), allNonBountyOffers as (
		SELECT  *
		FROM [DIMAIN_TR].[SLC_REPL].[dbo].[PartnerCommissionRule] pcr
		WHERE [DIMAIN_TR].[SLC_REPL].[dbo].[PartnerCommissionRule].[CommissionRate] > 0
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
SELECT [SLC_REPL].[dbo].[IronOffer].[PartnerID]
	  ,min([SLC_REPL].[dbo].[IronOffer].[StartDate]) as 'MinStartDate'
	  into #MinStartDate
FROM [SLC_REPL].[dbo].[IronOffer]

where [SLC_REPL].[dbo].[IronOffer].[IsDefaultCollateral] = 0 
and [SLC_REPL].[dbo].[IronOffer].[IsAboveTheLine] = 0 
and [SLC_REPL].[dbo].[IronOffer].[Name] not like 'Spare%'

group by [SLC_REPL].[dbo].[IronOffer].[PartnerID]
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
       ,[OP].[IronOfferID]	
	   ,[OP].[IronOfferName]		
	   ,[OP].[TopCashBackRate]
	   ,convert(date,[OP].[EndDate]) as 'EndDate'
	   ,convert(date,[OP].[StartDate]) as 'StartDate'
	   ,[OP].[IsNewOffer]
	   ,Case When [OP].[IsBaseOffer] = 1 Then 'Core Base' Else '' End as BaseOffer
	   ,ROW_NUMBER() over (order by [OP].[IsForcedInOfferIDs]desc,[OP].[IsBaseOffer],[OP].[IsRetailerLaunch]desc,[OP].[IsPlatinumRetailers]desc,[OP].[IsWel/Home/BirthOffer]desc,[OP].[TopCashBackRate]desc, [OP].[StartDate]) as 'Rank'
Into #OfferPostPriority
From #OfferPrePriority OP
Join [Derived].[Partner] P on OP.PartnerID = P.PartnerID 

IF OBJECT_ID('tempdb..#NameSplit') IS NOT NULL DROP TABLE #NameSplit
SELECT *
INTO #NameSplit
FROM (
Select #OfferPostPriority.[PartnerName]
       ,#OfferPostPriority.[AccountManager]
	   ,#OfferPostPriority.[Item]
       ,#OfferPostPriority.[IronOfferID]   
       ,#OfferPostPriority.[TopCashBackRate]
       ,#OfferPostPriority.[StartDate]
       ,#OfferPostPriority.[EndDate]
       ,#OfferPostPriority.[IsNewOffer]
       ,#OfferPostPriority.[BaseOffer]
       ,#OfferPostPriority.[IronOfferName]       
       ,#OfferPostPriority.[Rank]
	   ,RANK() OVER (PARTITION BY #OfferPostPriority.[IronOfferID] ORDER BY #OfferPostPriority.[ItemNumber] DESC) AS ItemNumberRev
	   ,COUNT(*) OVER (PARTITION BY #OfferPostPriority.[IronOfferID]) AS NameSplits
	   ,CASE WHEN #OfferPostPriority.[Item] LIKE '[A-Z][A-Z]%[0-9][0-9][0-9]' THEN 1 ELSE 0 END AS IsClientServiceRef
From #OfferPostPriority
Cross Apply [Warehouse].[dbo].[il_SplitDelimitedStringArray] ((#OfferPostPriority.[IronOfferName]), '/')) a

Select [opp].[PartnerName]
       ,[opp].[AccountManager]
	   , Coalesce(Max([opp].[ClientServicesRef]), '') as ClientServicesRef
	   , Coalesce(Max([opp].[CampaignType]), '') as CampaignType
	   , Coalesce(Max([opp].[OfferName]), '') as OfferName
       ,[opp].[IronOfferID]   
       ,[opp].[TopCashBackRate]
       ,[opp].[BaseOffer]
       ,[opp].[EndDate]
       ,[opp].[IsNewOffer]
 --      ,[IronOfferName]       
       ,[opp].[Rank]
From (
Select #NameSplit.[PartnerName]
       ,#NameSplit.[AccountManager]
	 , CASE
			WHEN #NameSplit.[IsClientServiceRef] = 1 THEN #NameSplit.[Item]
			ELSE ''
	   END AS ClientServicesRef
	 , CASE
			WHEN #NameSplit.[StartDate] > '2019-06-10' AND #NameSplit.[NameSplits] > 2 AND #NameSplit.[ItemNumberRev] = 2 THEN #NameSplit.[Item]
			WHEN #NameSplit.[StartDate] < '2019-06-10' AND #NameSplit.[NameSplits] > 4 AND #NameSplit.[ItemNumberRev] = 2 THEN #NameSplit.[Item]
			ELSE ''
	   END AS CampaignType
	 , CASE
			WHEN #NameSplit.[ItemNumberRev] = 1 THEN #NameSplit.[Item]
			ELSE ''
	   END AS OfferName
       ,#NameSplit.[IronOfferID]   
       ,#NameSplit.[TopCashBackRate]
       ,#NameSplit.[EndDate]
       ,#NameSplit.[IsNewOffer]
       ,#NameSplit.[BaseOffer]
       ,#NameSplit.[IronOfferName]       
       ,#NameSplit.[Rank]
FROM #NameSplit) opp
Group by [opp].[PartnerName]
       ,[opp].[AccountManager]
       ,[opp].[IronOfferID]   
       ,[opp].[IronOfferName]       
       ,[opp].[TopCashBackRate]
       ,[opp].[EndDate]
       ,[opp].[IsNewOffer]
       ,[opp].[BaseOffer]
       ,[opp].[Rank]
Order by [opp].[Rank]


END


