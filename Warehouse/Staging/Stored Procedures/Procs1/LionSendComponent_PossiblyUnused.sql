/*

	Author:		Stuart Barnley
	
	Date:		2016-10-21

	Purpose:	Where data is loaded to LionSendComponent but 
				does not correspond to an email send.
				
				This produces a list of possible LionSendIDs
				that to be removed

*/

Create Procedure Staging.LionSendComponent_PossiblyUnused
As 
--------------------------------------------------------------------------
-----------------------Produce a list of LionSendIDs----------------------
--------------------------------------------------------------------------
select LionSendID, COUNT(*) as [rows]
Into #t1
from warehouse.relational.LionSendComponent
Group by LionSendID

--------------------------------------------------------------------------
-----------Find those that are not in CampaignLionSendIDs table-----------
--------------------------------------------------------------------------

Select t.* 
into #Unneeded
From #t1 as t
Left Outer join warehouse.Relational.CampaignLionSendIDs as a
	on t.LionSendID = a.LionSendID
Where a.CampaignKey is null
Order By t.LionSendID Desc

---Display results

Select *
From #Unneeded
Order by LionSendID Desc