
Create Procedure Staging.RBSG_MonthlyRep
as
Declare @SDate date,@EDate date, @LDate date
Set @SDate = 'Aug 01, 2012'
Set @EDate = 'Jan 31, 2014'
Set @LDate = '08 Aug, 2013'
Exec Staging.RBSG_MonthlyRep_InMonth @SDate,@EDate, @LDate
Exec Staging.RBSG_MonthlyRep_MonthByMonthComms @SDate,@EDate
Exec Staging.RBSG_MonthlyRep_SpendEarnByPartner  @SDate,@EDate, @LDate
Exec Staging.RBSG_MonthlyRep_SpendEarnPrimacy @SDate,@EDate, @LDate
Exec Staging.RBSG_MonthlyRep_InMonthComms @EDate