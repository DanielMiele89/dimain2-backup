/*
		Date:			12th October 2015

		Author:			Stuart Barnley

		Purpose:		To make sure customers who are MyRewardsa accounts only are not
						ticked as on trial

*/
CREATE Procedure [Staging].[SLC_Report_Update_FanSFDDailyUploadData_DirectDebit]
as
-------------------------------------------------------------------------------------------------
---------------------Find offers for Household bills - Ontrial and MyRewards---------------------
-------------------------------------------------------------------------------------------------

Select	i.ID as IronOfferID,
		Case
			When i.StartDate < 'Oct 01, 2015' then 'Ontrial'
			Else 'MyRewards'
		End as MyRewards,
		i.EndDate
Into #Offers
from SLC_report.dbo.IronOffer as i
inner join SLC_Report.dbo.Partner as p
	on i.PartnerID = p.ID
Where P.name like '%Household%' 
		and i.Name like '%Base%'
-------------------------------------------------------------------------------------------------
---------------------Find customers on MyRewards who are currently ontrial-----------------------
-------------------------------------------------------------------------------------------------
Select dd.FanID
Into #MyRewardsCustomers
from slc_Report.dbo.FanSFDDailyUploadData_DirectDebit as dd
Where OnTrial = 1

-------------------------------------------------------------------------------------------------
-----------Find customers on both offers for Household bills - Ontrial and MyRewards-------------
-------------------------------------------------------------------------------------------------
Select FanID
Into #Ontrial 
from #MyRewardsCustomers as m
inner join slc_report.dbo.fan as f
	on m.FanID = f.ID
inner join SLC_Report.dbo.IronOfferMember as iom
	on f.CompositeID = iom.CompositeID
inner join #Offers as o
	on iom.IronOfferID = o.IronOfferID
Where	o.MyRewards = 'Ontrial' and 
		(	
			iom.EndDate is null or 
			iom.enddate > Cast(getdate() as date)
		) and
		o.EndDate > Cast(getdate() as date)
-------------------------------------------------------------------------------------------------
-------------------------------Set Ontrial to zero if not on trial anymore-----------------------
-------------------------------------------------------------------------------------------------		
Update slc_Report.dbo.FanSFDDailyUploadData_DirectDebit
Set OnTrial = 0
From slc_Report.dbo.FanSFDDailyUploadData_DirectDebit as dd
inner join #MyRewardsCustomers as a
	on dd.FanID = a.FanID
left outer join #Ontrial as o
	on a.FanID = o.fanid
Where o.FanID is null
-------------------------------------------------------------------------------------------------
-------------------------Remove other account names from MyRewardAccount field-------------------
-------------------------------------------------------------------------------------------------

Update warehouse.staging.SLC_Report_DailyLoad_Phase2DataFields
Set MyRewardAccount = ''
Where MyRewardAccount <> '' and MyRewardAccount Not like 'Reward%'

