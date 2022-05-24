
/*

	Author:		Stuart Barnley

	Date:		2016-06-08

	Purpose:	To Check Heatmap has run as expected

*/

CREATE Procedure [Staging].[GeoDemographicHeatMap_Checking] (@StartDate Date)
As
----------------------------------------------------------------------------------------
------------------------------------Show JobLog Entries---------------------------------
----------------------------------------------------------------------------------------
--Declare @StartDate Date

--Set @StartDate = '2016-06-04'

select * 
from Warehouse.Staging.joblog as jl
Where	jl.StoredProcedureName like '%heatmap%' and
		StartDate >= @StartDate

----------------------------------------------------------------------------------------
-----------------------------Calculate w=latest HeatMap Dates---------------------------
----------------------------------------------------------------------------------------

if object_id('tempdb..#PartnerInfo') is not null drop table #PartnerInfo
Select	PartnerName,
		p.PartnerID,
		Max(StartDate) as LastStartDate,
		Max(EndDate) as LastEndDate
Into #PartnerInfo
from Relational.Partner as p with (nolock)
inner join Relational.GeoDemographicHeatMap_Members geo (NOLOCK)
	ON p.PartnerID = geo.PartnerID
Group by PartnerName,p.PartnerID

----------------------------------------------------------------------------------------
-----------------------Work out how many entries were changed---------------------------
----------------------------------------------------------------------------------------

Select	Count(Distinct geo.MemberID) as ChangeCount,
		p.PartnerID
Into #ChangeCounts
from #PartnerInfo as p
inner join Relational.GeoDemographicHeatMap_Members geo (NOLOCK)
	on p.PartnerID = geo.PartnerID and
		(	p.LastEndDate = geo.EndDate or
			p.LastStartDate = geo.StartDate)
Group By p.PartnerID

----------------------------------------------------------------------------------------
-----------------------------------Display changes stats--------------------------------
----------------------------------------------------------------------------------------

SELECT  po.PartnerID,
		po.PartnerName,
		LastEndDate,
		LastStartDate,
		ChangeCount as TotalRows_Closed_and_Opened
FROM #ChangeCounts AS A
INNER JOIN #PartnerInfo AS PO
	ON A.PartnerID = PO.PartnerID
INNER JOIN WAREHOUSE.RELATIONAL.PARTNER AS P
	ON A.PartnerID = P.PartnerID
Order By LastStartDate Desc,
		 po.PartnerName