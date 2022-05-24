
CREATE Procedure [Staging].[RBSG_MonthlyRepV1_1]
as
Declare @SDate date,@EDate date, @LDate date
Set @SDate = 'Aug 01, 2012'
Set @EDate = 'Feb 28, 2014'
Set @LDate = '08 Aug, 2013'
Exec Staging.RBSG_MonthlyRep_InMonth @SDate,@EDate, @LDate
Exec Staging.RBSG_MonthlyRep_MonthByMonthComms @SDate,@EDate
Exec Staging.RBSG_MonthlyRep_SpendEarnByPartner  @SDate,@EDate, @LDate
Exec Staging.RBSG_MonthlyRep_SpendEarnPrimacy @SDate,@EDate, @LDate
Exec Staging.RBSG_MonthlyRep_InMonthCommsV1_1 @EDate