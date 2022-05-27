/*

	Author:		Stuart Barnley

	Date:		19th January 2017

	Purpose:	This is to return a list of Amazon Redemptions that have been ordered and/or
				cancelled - only Earn While you burn.
	
	Update:		SB 20th January 2017 - Removal of test redemption to avoid incorrect reporting

*/

CREATE Procedure Staging.SSRS_R0147_Amazon_Betterment_Redemptions
With Execute as Owner
As

/*--------------------------------------------------------------------------------------------------
--------------------------------Pull out the Earn While you burn entries----------------------------
----------------------------------------------------------------------------------------------------*/
if object_id('tempdb..#Reds') is not null drop table #Reds
Select	b.ID as RedemptionTranID,
		b.FanID,
		ri.PrivateDescription as RedemptionDescription,
		b.ClubCash as RewardsUsed,
		b.ProcessDate as RedemptionDate,
		Case
			When Cancelled.TransID is not null then 'Yes'
			Else 'No'
		End as Cancelled
Into #Reds
From SLC_report.dbo.Trans as b with (Nolock)
LEFT Outer JOIN (select ItemID as TransID from SLC_Report.dbo.trans t2 where t2.typeid=4) as Cancelled ON Cancelled.TransID=b.ID
inner join warehouse.relational.RedemptionItem as ri
	on	b.itemid = ri.RedeemID and
		typeid = 3 and itemid in (7235,7237,7239)
Where b.ID <> 316049131 -- Test Redemption
/*--------------------------------------------------------------------------------------------------
-----------------------------------------Display Results--------------------------------------------
----------------------------------------------------------------------------------------------------*/
Select * from #Reds