/*
	
	Author:		Stuart Barnley


	Date:		21st June 2017


	Purpose:	to produce a set of sample customers to b used to assess the Reward 2.0 collateral
				changes in some daily emails
	

*/

Create Procedure Staging.R_TMP_001
With Execute as Owner
As

---------------------------------------------------------------------------------------------------
---------------------------Find those customers who have first Earned on DD------------------------
---------------------------------------------------------------------------------------------------
Select *
Into #Reward20_SampleData
From (
		Select	'1. First Earn DD' as [Type],
				Case
					When ClubID = 132 then 'NatWest'
					Else 'RBS'
				End as Bank,
				Case
					When s.[CustomerSegment] is null then 'Core'
					When s.[CustomerSegment] = 'V' then 'Private'
					Else 'Core'
				End as RBSGSegment,
				a.FanID,
				Email,
				'N/A' as MyRewardAccount,
				'N/A' as Joint,
				'N/A' as CreditCard,
				ROW_NUMBER() OVER(PARTITION BY	ClubID,
										Case
											When s.[CustomerSegment] is null then 'Core'
											When s.[CustomerSegment] = 'V' then 'Private'
											Else 'Core'
										End
										ORDER BY Email ASC) AS RowNo
				From Warehouse.Staging.SLC_Report_DailyLoad_Phase2DataFields as a
				inner join warehouse.relational.Customer as c
					on a.FanID = c.FanID
				inner join warehouse.relationAL.Customer_RBSGSegments as s
					on	c.fanid = s.fanid and
						s.EndDate is null
				Where	FirstEarnType = 'Direct Debit Frontbook' and
						c.MarketableByEmail = 1 and
						c.Email not like '%-%'
		) as a
Where RowNo <= 5
---------------------------------------------------------------------------------------------------
--------------------------------Find those customers who have moved home---------------------------
---------------------------------------------------------------------------------------------------
Union All
Select *
From (
		Select	'2. Homemover' as [Type],
				Case
					When ClubID = 132 then 'NatWest'
					Else 'RBS'
				End as Bank,
				Case
					When s.[CustomerSegment] is null then 'Core'
					When s.[CustomerSegment] = 'V' then 'Private'
					Else 'Core'
				End as RBSGSegment,
				a.FanID,
				Email,
				'N/A' as MyRewardAccount,
				'N/A' as Joint,
				Case
					When IsCredit = 1 then 'Yes'
					Else 'No'
				End as CreditCard,
				ROW_NUMBER() OVER(PARTITION BY	ClubID,
										Case
											When s.[CustomerSegment] is null then 'Core'
											When s.[CustomerSegment] = 'V' then 'Private'
											Else 'Core'
										End,
										Case
											When IsCredit = 1 then 'Yes'
											Else 'No'
										End
										ORDER BY Email ASC) AS RowNo
				From Warehouse.Staging.SLC_Report_DailyLoad_Phase2DataFields as a
				inner join warehouse.relational.Customer as c
					on a.FanID = c.FanID
				inner join slc_report.[dbo].[FanSFDDailyUploadData] as b
					on a.FanID = b.FanID
				inner join warehouse.relationAL.Customer_RBSGSegments as s
					on	c.fanid = s.fanid and
						s.EndDate is null
				Where	Homemover = 1 and
						c.MarketableByEmail = 1 and
						c.Email not like '%-%'
		) as a
Where RowNo <= 5
---------------------------------------------------------------------------------------------------
---------------------------------------Product Monitoring 60 Days----------------------------------
---------------------------------------------------------------------------------------------------
Union All
Select *
From (
		Select	'3. Day 60 Account Name' as [Type],
				Case
					When ClubID = 132 then 'NatWest'
					Else 'RBS'
				End as Bank,
				Case
					When s.[CustomerSegment] is null then 'Core'
					When s.[CustomerSegment] = 'V' then 'Private'
					Else 'Core'
				End as RBSGSegment,
				a.FanID,
				Email,
				Day60AccountName as MyRewardAccount,
				'N/A' as Joint,
				'N/A' as CreditCard,
				ROW_NUMBER() OVER(PARTITION BY	ClubID,
										Case
											When s.[CustomerSegment] is null then 'Core'
											When s.[CustomerSegment] = 'V' then 'Private'
											Else 'Core'
										End, Day60AccountName
										ORDER BY Email ASC) AS RowNo
				From Warehouse.Staging.SLC_Report_ProductMonitoring as a
				inner join warehouse.relational.Customer as c
					on a.FanID = c.FanID
				inner join warehouse.relationAL.Customer_RBSGSegments as s
					on	c.fanid = s.fanid and
						s.EndDate is null
				Where	Day60AccountName is not null and
						c.MarketableByEmail = 1 and
						c.Email not like '%-%'
		) as a
Where RowNo <= 3
---------------------------------------------------------------------------------------------------
---------------------------------------Product Monitoring 120Days----------------------------------
---------------------------------------------------------------------------------------------------
Union All
Select *
From (
		Select	'4. Day 120 Account Name' as [Type],
				Case
					When ClubID = 132 then 'NatWest'
					Else 'RBS'
				End as Bank,
				Case
					When s.[CustomerSegment] is null then 'Core'
					When s.[CustomerSegment] = 'V' then 'Private'
					Else 'Core'
				End as RBSGSegment,
				a.FanID,
				Email,
				Day120AccountName as MyRewardAccount,
				Case
					When JointAccount = 0 then 'No'
					Else 'Yes'
				End as Joint,
				'N/A' as CreditCard,
				ROW_NUMBER() OVER(PARTITION BY	ClubID,
										Case
											When s.[CustomerSegment] is null then 'Core'
											When s.[CustomerSegment] = 'V' then 'Private'
											Else 'Core'
										End, Day120AccountName,
										Case
											When JointAccount = 0 then 'No'
											Else 'Yes'
										End
										ORDER BY Email ASC) AS RowNo
				From Warehouse.Staging.SLC_Report_ProductMonitoring as a
				inner join warehouse.relational.Customer as c
					on a.FanID = c.FanID
				inner join warehouse.relationAL.Customer_RBSGSegments as s
					on	c.fanid = s.fanid and
						s.EndDate is null
				Where	Day120AccountName is not null and
						c.MarketableByEmail = 1 and
						c.Email not like '%-%'
		) as a
Where RowNo <= 3

---------------------------------------------------------------------------------------------------
---------------------------------------Output Contacts of table------------------------------------
---------------------------------------------------------------------------------------------------

Select * 
from #Reward20_SampleData
Order by 1,2,3