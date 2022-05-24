/*

	Date:		6th April 2017

	Author:		Stuart Barnley

	Purpose:	To Provide states to marketing about the customer base


*/
CREATE Procedure [Staging].[SSRS_R0153_CustomerBalancesReview]
With Execute as Owner
as

IF OBJECT_ID ('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers
select	c.FanID,
		Case
			When Email like '%-%' then 0
			When m.MarketableID = 1 then 1
			Else 0
		End as Emailable,
		ClubID
Into #Customers
From warehouse.relational.Customer as c
inner join warehouse.relational.Customer_MarketableByEmailStatus_MI as m
	on	c.FanID = m.FanID and
		m.EndDate is null
Where c.CurrentlyActive = 1
--(3386945 row(s) affected)
---------------------------------------------------------------------------------------------------
-----------------------------------Find Private/Core and update Emailable--------------------------
---------------------------------------------------------------------------------------------------

IF OBJECT_ID ('tempdb..#CustomerData') IS NOT NULL DROP TABLE #CustomerData
Select	c.FanID,
		ClubID,
		Case
			When IsCredit = 0 and IsDebit = 0 then 0
			Else Emailable
		End as Emailable,
		LoyaltyAccount as Frontbook
Into #CustomerData
From #Customers as c
Inner join slc_report.dbo.FanSFDDailyUploadData as a
	on a.FanID = c.FanID
inner join Warehouse.staging.SLC_Report_DailyLoad_Phase2DataFields as b
	on c.FanID = b.FanID
--(3386533 row(s) affected)

Create Clustered index cix_CustomerDate_FanID on #CustomerData (FanID)

---------------------------------------------------------------------------------------------------
------------------------------------------Balances-------------------------------------------------
---------------------------------------------------------------------------------------------------
IF OBJECT_ID ('tempdb..#Balances') IS NOT NULL DROP TABLE #Balances

Select	cd.*,
		ClubCashAvailable,
		NTILE(10) OVER(PARTITION BY Emailable ORDER BY ClubCashAvailable DESC) AS Deciles 
Into #Balances
From #CustomerData as cd
inner join slc_report.dbo.fan as f
	on cd.FanID = f.ID
--(3386533 row(s) affected)
Create Clustered index cix_Balances_FanID on #Balances (FanID)

---------------------------------------------------------------------------------------------------
------------------------------------Create Rolled Up Date------------------------------------------
---------------------------------------------------------------------------------------------------

Truncate Table [Staging].[R_0153_CustomerBalancesReview]

Insert Into [Staging].[R_0153_CustomerBalancesReview]
Select	Emailable,
		Deciles,
		Sum(Case
				When ClubID = 132 and Frontbook = 0 then 1 
				Else 0 
			End) as NWB_Customers,
		Sum(Case
				When ClubID = 132 and Frontbook = 0 then ClubCashAvailable 
				Else 0 
			End) as NWB_Available,
		Sum(Case
				When ClubID = 132 and Frontbook = 1 then 1 
				Else 0 
			End) as NWF_Customers,
		Sum(Case
				When ClubID = 132 and Frontbook = 1 then ClubCashAvailable 
				Else 0 
			End) as NWF_Available,
		Sum(Case
				When ClubID = 138 and Frontbook = 0 then 1 
				Else 0 
			End) as RBSB_Customers,
		Sum(Case
				When ClubID = 138 and Frontbook = 0 then ClubCashAvailable 
				Else 0 
			End) as RBSB_Available,		
		Sum(Case
				When ClubID = 138 and Frontbook = 1 then 1 
				Else 0 
			End) as RBSF_Customers,
		Sum(Case
				When ClubID = 138 and Frontbook = 1 then ClubCashAvailable 
				Else 0 
			End) as RBSF_Available					
--Into [Staging].[R_0153_CustomerBalancesReview]
From #Balances
Group by Deciles,Emailable
Order by Emailable Desc, Deciles