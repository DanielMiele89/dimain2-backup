
CREATE PROCEDURE [Staging].[SSRS_R0187_SFD_DailyTriggerEmails]

AS
BEGIN

/***********************************************************************************************************************
		Temporary fix until Trigger email counts are calculated in Wrehouse build - Runs sProc to populate tables
***********************************************************************************************************************/

--	Exec [SmartEmail].[DailyData_CustomersReceivingTriggerEmails]


/***********************************************************************************************************************
					  Generate a list of primary and secondary colours to be used in SSRS report
***********************************************************************************************************************/

If OBJECT_ID('tempdb..#ColourList') Is Not Null Drop Table #ColourList
SELECT 1 AS PrimaryColourID
	 , 1 AS SecondaryColourGroupID
	 , '#EA0C5C' AS PrimaryColourHexCode
	 , '#FF608E' AS SecondaryColourHexCode
INTO #ColourList
UNION
SELECT 1 AS PrimaryColourID
	 , 2 AS SecondaryColourGroupID
	 , '#EA0C5C' AS PrimaryColourHexCode
	 , '#AA002F' AS SecondaryColourHexCode
UNION
SELECT 2 AS PrimaryColourID
	 , 1 AS SecondaryColourGroupID
	 , '#1E5CC0' AS PrimaryColourHexCode
	 , '#688EF9' AS SecondaryColourHexCode
UNION
SELECT 2 AS PrimaryColourID
	 , 2 AS SecondaryColourGroupID
	 , '#1E5CC0' AS PrimaryColourHexCode
	 , '#00308A' AS SecondaryColourHexCode


/***********************************************************************************************************************
	 Fetch all entries from the DailyData_TriggerEmailCounts table populating additional fields for SSRS formatting
***********************************************************************************************************************/
	
DECLARE @SendDateFrom DATE = DATEADD(MONTH, -2, GETDATE())

If OBJECT_ID('tempdb..#EmailList') Is Not Null Drop Table #EmailList
Select DENSE_RANK() Over (Order by te.SendDate desc) as SendDateOrder
	 , te.SendDate
	 , te.TriggerEmail
	 , te.Brand
	 , te.Loyalty
	 , te.CustomersEmailed
	 , DENSE_RANK() Over (Order By te.TriggerEmail) % 2 + 1 as TriggerEmailID
	 , DENSE_RANK() Over (Partition by te.TriggerEmail Order By te.Brand) as BrandID
Into #EmailList
From Warehouse.SmartEmail.DailyData_TriggerEmailCounts te
WHERE te.TriggerEmail NOT LIKE 'Homemovers%'
AND te.SendDate > @SendDateFrom
Order by te.SendDate desc
		,te.TriggerEmail
		,te.Brand
		,te.Loyalty

/***********************************************************************************************************************
				Combine the email counts dataset with the colour list created for the SSRS report
***********************************************************************************************************************/
		
If OBJECT_ID('tempdb..#ColourAndEmailList') Is Not Null Drop Table #ColourAndEmailList
Select Distinct el.SendDate
			  , el.SendDateOrder
			  , el.TriggerEmail
			  , el.Brand
			  , el.Loyalty
			  , el.CustomersEmailed
			  , cl.PrimaryColourHexCode as TriggerEmailColourHexCode
			  , cl.SecondaryColourHexCode as BrandColourHexCode
			  , Case 
					When el.Loyalty = 'Core' then '#7a7a7a'
					When el.Loyalty = 'Prime' then '#5c5c5c'
					Else null
				End as LoyaltyColourHexCode
Into #ColourAndEmailList
From #EmailList el
Inner join #ColourList cl
	on	el.TriggerEmailID = cl.PrimaryColourID
	and	el.BrandID = cl.SecondaryColourGroupID
Order by el.SendDate desc
		,el.TriggerEmail
		,el.Brand
		,el.Loyalty


/***********************************************************************************************************************
				Step to identify days that extend further back than full weeks back from current date
						These rows are then filtered out from weekly comparison in the report
***********************************************************************************************************************/

DECLARE @DistinctRowCombination INT = (Select Count(1) From (Select Distinct TriggerEmail, Brand, Loyalty From #ColourAndEmailList) a)
DECLARE @RowCount INT = (Select Count(*) From #ColourAndEmailList) - (Select (Count(*) / @DistinctRowCombination) % 7 From #ColourAndEmailList) * @DistinctRowCombination

If @RowCount = 0
	Begin
		Set @RowCount = (Select Count(*) From #ColourAndEmailList)
	End
	
If OBJECT_ID('tempdb..#IncludeInWeeklyComparison') Is Not Null Drop Table #IncludeInWeeklyComparison
Select Top (@RowCount) SendDate
					 , TriggerEmail
					 , Brand
					 , Loyalty
					 , 1 as IncludeInWeeklyComparison
Into #IncludeInWeeklyComparison
From #ColourAndEmailList
Order by SendDate desc

/***********************************************************************************************************************
   Full dataset in then created with entries from withn the previous 7 days replicated for ease of use in SSES report
***********************************************************************************************************************/

Select [main].SendDate
	 , [main].SendDateOrder
	 , [main].SendDatePeriod
	 , [main].TriggerEmail
	 , [main].Brand
	 , [main].Loyalty
	 , [main].CustomersEmailed
	 , [main].CustomersEmailed_Last7Days
	 , [main].TriggerEmailColourHexCode
	 , [main].BrandColourHexCode
	 , [main].LoyaltyColourHexCode
	 , Coalesce(IncludeInWeeklyComparison,0) as IncludeInWeeklyComparison
From (
	Select SendDate
		 , SendDateOrder
		 , NULL as SendDatePeriod
		 , TriggerEmail
		 , Brand
		 , Loyalty
		 , CustomersEmailed
		 , Sum(Case
				When SendDate Between Dateadd(day,-6,CONVERT(Date,GETDATE())) And CONVERT(Date,GETDATE()) then 0
				Else CustomersEmailed
		   End) Over (Partition by SendDate, TriggerEmail) as CustomersEmailed_Last7Days
		 , TriggerEmailColourHexCode
		 , BrandColourHexCode
		 , LoyaltyColourHexCode
	From #ColourAndEmailList

	Union all

	Select SendDate
		 , SendDateOrder
		 , 'Last 7 days' as SendDatePeriod
		 , TriggerEmail + ' - Last 7 days' as TriggerEmail
		 , Brand
		 , Loyalty
		 , 0 as CustomersEmailed
		 , Sum(CustomersEmailed) Over (Partition by SendDate, TriggerEmail) as CustomersEmailed_Last7Days
		 , TriggerEmailColourHexCode
		 , BrandColourHexCode
		 , LoyaltyColourHexCode
	From #ColourAndEmailList
	Where SendDate Between Dateadd(day,-6,CONVERT(Date,GETDATE())) And CONVERT(Date,GETDATE())) [main]
Left join #IncludeInWeeklyComparison wc
	on	[main].SendDate = wc.SendDate
	and	Replace([main].TriggerEmail,' - Last 7 days','') = wc.TriggerEmail
	and [main].Brand = wc.Brand
	and [main].Loyalty = wc.Loyalty

END