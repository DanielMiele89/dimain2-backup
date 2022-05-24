Create Procedure Staging.[SSRS_R0062_CustomerBalances]
AS

Select  'All Activated' as CustomerType,
		Case
			When cb.ClubCashAvailable <= 0 then '01. <=£0'
			When cb.ClubCashAvailable < 0.5 then '02. £0.00-£0.49'
			When cb.ClubCashAvailable < 1 then '03. £0.50-£0.99'
			When cb.ClubCashAvailable < 1.5 then '04. £1.00-£1.49'
			When cb.ClubCashAvailable < 2 then '05. £1.50-£1.99'
			When cb.ClubCashAvailable < 2.5 then '06. £2.00-£2.49'
			When cb.ClubCashAvailable < 3 then '07. £2.50-£2.99'
			When cb.ClubCashAvailable < 3.5 then '08. £3.00-£3.49'
			When cb.ClubCashAvailable < 4 then '09. £3.50-£3.99'
			When cb.ClubCashAvailable < 4.5 then '10. £4.00-£4.49'
			When cb.ClubCashAvailable < 5 then '11. £4.50-£4.99'
			When cb.ClubCashAvailable < 7.5 then '12. £5.00-£7.49'
			Else '13. £7.50+'
		End as Balance,
		Sum(Case
				When ClubID = 132 and Registered = 1 then 1
				Else 0
			End) as NW_Registered,
		Sum(Case
				When ClubID = 132 and Registered <> 1 then 1
				Else 0
			End) as NW_Unregistered,
		Sum(Case
				When ClubID = 138 and Registered = 1 then 1
				Else 0
			End) as RBS_Registered,
		Sum(Case
				When ClubID = 138 and Registered <> 1 then 1
				Else 0
			End) as RBS_Unregistered
From Warehouse.relational.Customer as c
inner join Warehouse.Staging.Customer_CashbackBalances as cb
	on	c.FanID = cb.FanID and
		cb.[Date] = Cast(getdate() as date)
Where CurrentlyActive = 1
Group by Case
			When cb.ClubCashAvailable <= 0 then '01. <=£0'
			When cb.ClubCashAvailable < 0.5 then '02. £0.00-£0.49'
			When cb.ClubCashAvailable < 1 then '03. £0.50-£0.99'
			When cb.ClubCashAvailable < 1.5 then '04. £1.00-£1.49'
			When cb.ClubCashAvailable < 2 then '05. £1.50-£1.99'
			When cb.ClubCashAvailable < 2.5 then '06. £2.00-£2.49'
			When cb.ClubCashAvailable < 3 then '07. £2.50-£2.99'
			When cb.ClubCashAvailable < 3.5 then '08. £3.00-£3.49'
			When cb.ClubCashAvailable < 4 then '09. £3.50-£3.99'
			When cb.ClubCashAvailable < 4.5 then '10. £4.00-£4.49'
			When cb.ClubCashAvailable < 5 then '11. £4.50-£4.99'
			When cb.ClubCashAvailable < 7.5 then '12. £5.00-£7.49'
			Else '13. £7.50+'
		End

Union All

Select  'Marketable By Email' as CustomerType,
		Case
			When cb.ClubCashAvailable <= 0 then '01. <=£0'
			When cb.ClubCashAvailable < 0.5 then '02. £0.00-£0.49'
			When cb.ClubCashAvailable < 1 then '03. £0.50-£0.99'
			When cb.ClubCashAvailable < 1.5 then '04. £1.00-£1.49'
			When cb.ClubCashAvailable < 2 then '05. £1.50-£1.99'
			When cb.ClubCashAvailable < 2.5 then '06. £2.00-£2.49'
			When cb.ClubCashAvailable < 3 then '07. £2.50-£2.99'
			When cb.ClubCashAvailable < 3.5 then '08. £3.00-£3.49'
			When cb.ClubCashAvailable < 4 then '09. £3.50-£3.99'
			When cb.ClubCashAvailable < 4.5 then '10. £4.00-£4.49'
			When cb.ClubCashAvailable < 5 then '11. £4.50-£4.99'
			When cb.ClubCashAvailable < 7.5 then '12. £5.00-£7.49'
			Else '13. £7.50+'
		End as Balance,
		Sum(Case
				When ClubID = 132 and Registered = 1 then 1
				Else 0
			End) as NW_Registered,
		Sum(Case
				When ClubID = 132 and Registered <> 1 then 1
				Else 0
			End) as NW_Unregistered,
		Sum(Case
				When ClubID = 138 and Registered = 1 then 1
				Else 0
			End) as RBS_Registered,
		Sum(Case
				When ClubID = 138 and Registered <> 1 then 1
				Else 0
			End) as RBS_Unregistered
From Warehouse.relational.Customer as c
inner join Warehouse.Staging.Customer_CashbackBalances as cb
	on	c.FanID = cb.FanID and
		cb.[Date] = Cast(getdate() as date)
Where CurrentlyActive = 1 and MarketableByEmail = 1
Group by Case
			When cb.ClubCashAvailable <= 0 then '01. <=£0'
			When cb.ClubCashAvailable < 0.5 then '02. £0.00-£0.49'
			When cb.ClubCashAvailable < 1 then '03. £0.50-£0.99'
			When cb.ClubCashAvailable < 1.5 then '04. £1.00-£1.49'
			When cb.ClubCashAvailable < 2 then '05. £1.50-£1.99'
			When cb.ClubCashAvailable < 2.5 then '06. £2.00-£2.49'
			When cb.ClubCashAvailable < 3 then '07. £2.50-£2.99'
			When cb.ClubCashAvailable < 3.5 then '08. £3.00-£3.49'
			When cb.ClubCashAvailable < 4 then '09. £3.50-£3.99'
			When cb.ClubCashAvailable < 4.5 then '10. £4.00-£4.49'
			When cb.ClubCashAvailable < 5 then '11. £4.50-£4.99'
			When cb.ClubCashAvailable < 7.5 then '12. £5.00-£7.49'
			Else '13. £7.50+'
		End