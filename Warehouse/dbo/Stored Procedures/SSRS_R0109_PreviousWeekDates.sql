Create Procedure SSRS_R0109_PreviousWeekDates as
Select [Staging].[fnGetStartOfWeek](getdate()) as EndDate,Dateadd(day,-6,[Staging].[fnGetStartOfWeek](getdate())) as StartDate