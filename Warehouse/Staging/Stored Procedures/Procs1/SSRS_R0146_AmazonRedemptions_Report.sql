CREATE Procedure [Staging].[SSRS_R0146_AmazonRedemptions_Report]
With Execute as Owner
as
------------------------------------------------------------------------------
-------------------------------Find redemption entries------------------------
------------------------------------------------------------------------------
if object_id('tempdb..#redeemers') is not null drop table #redeemers
SELECT t.fanid, 
       clubcash        AS RewardsUsed, 
       r.id            AS RedeemID,
	   Case
			When a.FanID is null then 'No'
			Else 'Yes'
	   End as EmailOpener
INTO   #redeemers 
FROM   slc_report.dbo.trans AS T 
       INNER JOIN slc_report.dbo.redeem AS r 
               ON t.itemid = r.id 
		Left Outer join (Select Distinct FanID From Warehouse.InsightArchive.AmazonRedemptions_OpenedEmails) as a
			on t.FanID = a.FanID
		inner join Warehouse.relational.AmazonRedemptionCustomers_20170120 as b
						--warehouse.InsightArchive.AmazonRedemptionOfferCustomers as b
			on t.fanid = b.FanID
WHERE  typeid = 3 
       AND itemid IN ( 7235, 7236, 7237, 7238, 
                       7239, 7240 )  
------------------------------------------------------------------------------
------------------------Create Redemption Item Table--------------------------
------------------------------------------------------------------------------
if object_id('tempdb..#RedeemIDs') is not null drop table #RedeemIDs
Select	Case
			When ri.ID in (7235,7237,7239) then 'Traditional'
			Else 'Earn While you Burn'
		End as [RedeemType],
		ID as RedeemID,
		'No' as EmailOpener,
		Description as [PrivateDescription]
Into #RedeemIDs
From SLC_report.dbo.Redeem as ri
Where ri.ID in( 7235, 7236, 7237, 7238, 
                       7239, 7240 )  
Union All
Select	Case
			When ri.ID in (7235,7237,7239) then 'Traditional'
			Else 'Earn While you Burn'
		End as [RedeemType],
		ID as RedeemID,
		'Yes' as EmailOpener,
		Description as [PrivateDescription]
From SLC_report.dbo.Redeem as ri
Where ri.ID in( 7235, 7236, 7237, 7238, 
                       7239, 7240 )  

------------------------------------------------------------------------------
-------------------------------Find redemption entries------------------------
------------------------------------------------------------------------------
if object_id('tempdb..#AmazonStats') is not null drop table #AmazonStats
Select	ri.RedeemID,
		ri.[RedeemType],
		ri.PrivateDescription as RedemptionDescription,
		ri.EmailOpener,
		Sum(Case
				When r.FanID is null then 0
				Else 1
			End) as Redemptions,
		Coalesce(Sum(RewardsUsed),0) as RewardsUsed,
		Coalesce(Sum(Case
						When r.RedeemID in (7235,7237,7239) then 0
						Else (RewardsUsed*0.05)
					 End),0) as RewardsEarned,
		Sum(Case
				When c.CustomerType = 'Amazon_TU' then 1
				Else 0
			End) as AmazonTU,
		Sum(Case
				When c.CustomerType = 'Amazon_NonTU' then 1
				Else 0
			End) as AmazonNonTU,
		Sum(Case
				When c.CustomerType = 'NonAmazon_TU' then 1
				Else 0
			End) as NonAmazon_TU,
		Sum(Case
				When c.CustomerType = 'NonAmazon_NonTU' then 1
				Else 0
			End) as NonAmazon_NonTU,
		Sum(Case
				When c.CustomerType like '%seed%' then 1
				Else 0
			End) as SeedRecords
From	#RedeemIDs as ri
Left Outer Join #Redeemers as r
	on	ri.RedeemID = r.RedeemID and
		ri.EmailOpener = r.EmailOpener
Left Outer join Warehouse.relational.AmazonRedemptionCustomers_20170120 as c
	on r.FanID = c.FanID
Group By ri.RedeemID,ri.[RedeemType],	ri.PrivateDescription,ri.EmailOpener