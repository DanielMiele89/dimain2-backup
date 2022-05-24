CREATE Procedure [Staging].[SSRS_R0146_AmazonRedemptions_Report_V2]
--With Execute as Owner
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
		Description as [PrivateDescription],
		Case 
			when ri.ID = 7235 then cast(0.5 as real)
			when ri.ID = 7237 then cast(1 as real)
			when ri.ID = 7239 then cast(2.5 as real)
			else NULL
		End as [Savings]
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
		Description as [PrivateDescription],
		Case 
			when ri.ID = 7235 then cast(0.5 as real)
			when ri.ID = 7237 then cast(1 as real)
			when ri.ID = 7239 then cast(2.5 as real)
			else NULL
		End as [Savings]
From SLC_report.dbo.Redeem as ri
Where ri.ID in( 7235, 7236, 7237, 7238, 
                       7239, 7240 )  

			
			   

					   

------------------------------------------------------------------------------
-------------------------------Find redemption entries------------------------
------------------------------------------------------------------------------
if object_id('tempdb..#AmazonStats') is not null drop table #AmazonStats
Select	
		row_number() over (partition by ri.redeemtype order by ri.redeemtype) [RowNum],
		ri.RedeemID,
		ri.[RedeemType],
		x.DISTINCTCUSTOMERS [UniqueCustomersType],
		y.multipleacrosstypes [MultipleRedeemsAcrossTypes],
		ri.PrivateDescription as RedemptionDescription,
		ri.EmailOpener,
		Sum(Case
				When r.FanID is null then 0
				Else 1
			End) as Redemptions,
		count(distinct r.FanID) as UniqueCustomers,
		mr.RedemptionsMultiple as MultipleRedeemers,
		Coalesce(Sum(RewardsUsed),0) as RewardsUsed,
		Coalesce(Sum(Case
						When r.RedeemID in (7235,7237,7239) then 0
						Else (RewardsUsed*0.05)
						End),0) as [RewardsEarned],
		isnull(cast(count(r.fanid) as int) * cast(ri.savings as real), 0) [BettermentValue],
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
-- ***** Comment by ZT '2017-03-06': Added to get the count of customers with multiple redemptions  *****
Left Outer Join (
				SELECT RedeemID, EmailOpener, COUNT(1) RedemptionsMultiple FROM (
							SELECT RedeemID, EmailOpener, FanID FROM #Redeemers 
							GROUP BY RedeemID, EmailOpener, FanID
							HAVING COUNT(1) > 1
				) x
				GROUP BY RedeemID, x.EmailOpener
) as mr
	on	mr.RedeemID = r.RedeemID AND mr.EmailOpener = r.EmailOpener
-- ***** Comment by ZT '2017-03-06': added to get unique customers across redeem type  *****
LEFT OUTER JOIN (
	SELECT Case
			When r.redeemID in (7235,7237,7239) then 'Traditional'
			Else 'Earn While you Burn'
		End as [RedeemType], COUNT(distinct fanid) [DISTINCTCUSTOMERS] FROM 
	#REDEEMERS R
	GROUP BY Case
			When r.redeemID in (7235,7237,7239) then 'Traditional'
			Else 'Earn While you Burn'
		End) x 
	on x.RedeemType = ri.redeemtype
-- ***** Comment by ZT '2017-03-07': Added to get the number of customers that redeemed across more than one type  *****
Left Outer Join (select redeemtype, count(a.fanid) [multipleacrosstypes] from (
						select distinct r1.fanid, 
										count(distinct r1.redeemid) [countofredemptions], 
										Case
											When r2.redeemID in (7235,7237,7239) then 'Traditional'
											Else 'Earn While you Burn'
										End as [RedeemType]
						from #redeemers r1
						left join #redeemers r2 
								on r1.fanid = r2.fanid 
						group by r1.fanid, r2.redeemid
						having count(distinct r1.redeemid) > 1
						) a
				group by redeemtype
			) y on y.RedeemType = ri.redeemtype
Group By ri.RedeemID,ri.[RedeemType],	ri.PrivateDescription,ri.EmailOpener, mr.RedemptionsMultiple, ri.savings, x.DISTINCTCUSTOMERS, y.multipleacrosstypes
ORDER BY ri.RedeemID,ri.[RedeemType],	ri.PrivateDescription,ri.EmailOpener