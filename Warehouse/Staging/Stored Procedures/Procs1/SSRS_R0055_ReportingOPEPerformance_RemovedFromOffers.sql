/*
	Author:		Stuart Barnley

	Date:		2nd June 2015

	Description - this looks at those people removed from offers in the last email sent

				  This data is organised in by customers and by Campaigns
*/

CREATE Procedure Staging.SSRS_R0055_ReportingOPEPerformance_RemovedFromOffers
as
------------------------------------------------------------------------------
------------------------------------------------------------------------------
------------------------------------------------------------------------------
IF OBJECT_ID ('tempdb..#t1') IS NOT NULL DROP TABLE #t1
Select	*
into #t1
from 
(SELECT	LionSendID,
	CAST(Staging.fnGetStartOfWeek(ec.SendDate)+1 AS DATE) as SendWeekCommencing,
	ROW_NUMBER() OVER (ORDER BY CAST(Staging.fnGetStartOfWeek(ec.SendDate)+1 AS DATE) Desc) AS RowNumber
--INTO #t1--Warehouse.Staging.R_0055_LionSendWeek
FROM Relational.CampaignLionSendIDs c
INNER JOIN Relational.EmailCampaign ec
	ON c.CampaignKey = ec.CampaignKey
) as a
Where RowNumber = 1
------------------------------------------------------------------------------
------------------------------------------------------------------------------
------------------------------------------------------------------------------
Truncate Table Staging.R_0055_RemovedFromOffers_Customers
Insert Into Staging.R_0055_RemovedFromOffers_Customers
Select	Offers,
		Count(*) as Customers,
		Count(*) * Offers as TotalOffers

from 
(
select	FanID,
		Count(*) as Offers
from #t1 as t
inner join relational.IronOffer as i
	on t.SendWeekCommencing < i.StartDate
inner join [Relational].[Campaign_History_OPE_Removal] as ope
	on i.IronOfferID = OPE.IronOfferID
Where i.IsTriggerOffer = 0
Group by FanID
) as a
Group By Offers
Order by Offers
------------------------------------------------------------------------------
------------------------------------------------------------------------------
------------------------------------------------------------------------------
Truncate Table Staging.R_0055_RemovedFromOffers_Campaigns
Insert Into Staging.R_0055_RemovedFromOffers_Campaigns

select	cn.ClientServicesRef,cn.CampaignName,i.IronOfferID,Count(Distinct FanID) as Customers
from #t1 as t
inner join relational.IronOffer as i
	on t.SendWeekCommencing < i.StartDate
inner join [Relational].[Campaign_History_OPE_Removal] as ope
	on i.IronOfferID = OPE.IronOfferID
Left Outer join relational.IronOffer_Campaign_HTM as cam
	on i.IronOfferID = cam.IronOfferID
Left Outer join relational.CBP_CampaignNames as cn
	on cam.ClientServicesRef = cn.ClientServicesRef
Where i.IsTriggerOffer = 0
Group By i.IronOfferID,cn.ClientServicesRef,cn.CampaignName
