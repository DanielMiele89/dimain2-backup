/*

	Author:		Stuart Barnley

	Date:		19th January 2017

	Purpose:	This is to return a list of Amazon Redemptions that have been ordered and/or
				cancelled - only Earn While you burn.
	
	Update:		SB 20th January 2017 - Removal of test redemption to avoid incorrect reporting

*/

CREATE Procedure Staging.SSRS_R0147_Amazon_EWYB_Redemptions
With Execute as Owner
As

/*--------------------------------------------------------------------------------------------------
--------------------------------Pull out the Earn While you burn entries----------------------------
----------------------------------------------------------------------------------------------------*/
if object_id('tempdb..#Trans') is not null drop table #Trans
Select	t.ID as TranID,
		Max(t.TypeiD) as TypeID,
		t.FanID,
		Max(t.ProcessDate) as ProcessDate,
		t.ClubCash* tt.Multiplier	as CashbackEarned,
		t.ActivationDays,
		t.ItemID
Into #Trans
From SLC_Report.dbo.Trans as t with (Nolock)
inner join SLC_Report.dbo.TransactionType as tt with (Nolock)
	on t.TypeID = tt.ID		
inner join SLC_Report.dbo.fan as c with (Nolock)
		on t.FanID = c.ID
Where	TypeID in (26,27) and
		clubid in (132,138)
Group by t.ID,t.FanID,t.ClubCash* tt.Multiplier,t.ActivationDays,t.ItemID

Create Clustered Index i_Trans_ItemID on #Trans (ItemID)
/*--------------------------------------------------------------------------------------------------
---------------------------Find out the linked redemptions which Redemption-------------------------
----------------------------------------------------------------------------------------------------*/
if object_id('tempdb..#RedsPlusEarn') is not null drop table #RedsPlusEarn
Select	b.ID as RedemptionTranID,
		a.FanID,
		ri.PrivateDescription as RedemptionDescription,
		Case
			When a.TypeID = 27 then 0
			Else b.ClubCash
		End	as RewardsUsed,
		b.ProcessDate as RedemptionDate,
		Case
			When a.typeid = 27 then 'Yes'
			Else 'No'
		End as Cancelled,
		a.TranID,
		Case
			When a.TypeID = 27 then 0
			Else a.CashbackEarned
		End as RewardsEarned,
		a.ProcessDate as EarnDate
Into #RedsPlusEarn
From #Trans as a
inner join SLC_report.dbo.Trans as b with (Nolock)
	on a.ItemID = b.ID
--inner join SLC_Report.dbo.TransactionType as tt with (Nolock)
--	on b.TypeID = tt.ID
inner join warehouse.relational.RedemptionItem as ri
	on b.itemid = ri.RedeemID
Where b.ID <> 316049131 -- Test Redemption
/*--------------------------------------------------------------------------------------------------
-----------------------------------------Display Results--------------------------------------------
----------------------------------------------------------------------------------------------------*/
Select * from #RedsPlusEarn