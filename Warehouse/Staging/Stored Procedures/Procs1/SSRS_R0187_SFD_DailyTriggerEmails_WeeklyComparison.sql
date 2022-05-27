
CREATE PROCEDURE [Staging].[SSRS_R0187_SFD_DailyTriggerEmails_WeeklyComparison]

AS
BEGIN

/***********************************************************************************************************************
	 Fetch all entries from the DailyData_TriggerEmailCounts table populating additional fields for SSRS formatting
***********************************************************************************************************************/

DECLARE @SendDateFrom DATE = DATEADD(MONTH, -6, GETDATE())

If OBJECT_ID('tempdb..#EmailList') Is Not Null Drop Table #EmailList
Select DENSE_RANK() Over (Order by te.SendDate desc) as SendDateOrder
	 , te.SendDate
	 , DatePart(weekday,te.SendDate) - 2 as WeekDayNumber
	 , DateName(dw,DatePart(weekday,te.SendDate) - 2) as WeekDayName
	 , te.TriggerEmail
	 , te.Brand
	 , te.Loyalty
	 , te.CustomersEmailed
	 , CASE WHEN SendDate > DATEADD(DAY, -7, GETDATE()) THEN 1 ELSE 0 END AS IsThisWeek
Into #EmailList
From Warehouse.SmartEmail.DailyData_TriggerEmailCounts te
WHERE TriggerEmail NOT LIKE 'Homemovers%'
AND te.SendDate > @SendDateFrom
Order by te.SendDate desc
		,te.TriggerEmail
		,te.Brand
		,te.Loyalty
		
SELECT [main].DateRange
	 , [main].WeekDayName
	 , [main].WeekDayNumber
	 , [main].TriggerEmail
	 , [main].Brand
	 , [main].Loyalty
	 , [main].CustomersEmailed
FROM (	Select 'Previous 7 Days' as DateRange
			 , WeekDayName
			 , WeekDayNumber
			 , TriggerEmail
			 , Brand
			 , Loyalty
			 , CustomersEmailed
		From #EmailList
		WHERE IsThisWeek = 1

		Union

		Select 'Average all time' as DateRange
			 , WeekDayName
			 , WeekDayNumber
			 , TriggerEmail
			 , Brand
			 , Loyalty
			 , AVG(CustomersEmailed) as CustomersEmailed
		From #EmailList
		Group by WeekDayName
			 , WeekDayNumber
			 , TriggerEmail
			 , Brand
			 , Loyalty) [main]

Order by [main].TriggerEmail
	   , [main].Brand
	   , [main].Loyalty
	   , [main].DateRange
	   , [main].WeekDayNumber

End
