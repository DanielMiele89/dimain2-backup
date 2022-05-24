CREATE procedure [Staging].[SSRS_R0154_PartnerDealsErrorReport]
As 
begin

IF Object_id('tempdb..#T1') IS NOT NULL  DROP TABLE #T1

SELECT DISTINCT 
	ID
	, ColumnToCheck
INTO #T1
FROM Staging.R_0154_PartnerDealsErrorReport


Select distinct 
	ErrorID
	, Message
	, ColumnToCheck
	, y.ID
	, ClubID
	, ClubName
	, PartnerID
	, PartnerName
	, x.Description [ManagedBy]
	, StartDate
	, EndDate
	, Override
	, Publisher
	, Reward
	, FixedOverride
	, stuff(
		(select DISTINCT ',' + t.ColumnToCheck FROM #T1 t WHERE t.ID = y.ID FOR XML PATH(''))
		, 1, 1, ''
	) ColumnConcat
From Staging.R_0154_PartnerDealsErrorReport y
Left join Relational.nFIPartnerDeals_Relationship_V2 x
	on x.ID = y.ManagedBy
	 
END