/*
	Author:			Stuart Barnley

	Date:			29th December 2015

	Purpose:		This lists those redemptions that are yet to be logged
					in RedemptionItems and TradeUpValue

*/

CREATE Procedure [Staging].[SSRS_R0111_New_Redemption_Items]
as

-----------------------------------------------------------------------------------
--------------------------------List of un-logged Redemptions----------------------
-----------------------------------------------------------------------------------

if object_id('tempdb..#t1') is not null drop table #t1
select r.ID as RedeemID
	 , r.[Description] as Redeem_Desc
	 , r.SupplierID
Into #t1
From SLC_Report..Redeem as r with (nolock)
Left join Relational.RedemptionItem_TradeUpValue ri with (nolock)
	on r.ID = ri.RedeemID
Left join Staging.R_0111_Exclusions e with (nolock) ---- Those items already assessed and excluded
	on r.ID = e.RedeemID
Where ri.RedeemID Is Null
And e.RedeemID Is Null
And r.ID > 7226
Order by r.ID Desc

-----------------------------------------------------------------------------------
--------------------Return list of Unlogged items and suppliers--------------------
-----------------------------------------------------------------------------------
Select RedeemID
	 , Redeem_Desc
	 , [Description] as Supplier
	 , [Status]
From #t1 as t
Left Outer join SLC_Report..RedeemSupplier as rs with (nolock)
	on t.SupplierID = rs.ID