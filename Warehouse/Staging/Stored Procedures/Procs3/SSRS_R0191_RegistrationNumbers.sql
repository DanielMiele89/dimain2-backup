
CREATE PROCEDURE Staging.SSRS_R0191_RegistrationNumbers (@StartDate datetime, @EndDate datetime)
AS
Begin

--declare @startdate datetime = '2018-11-05 00:00:00.000'
--, @enddate datetime = '2018-11-11 00:00:00.000'

Declare @EndDateCalc datetime = dateadd( ss, -1, dateadd(d, 1, @Enddate) )


	select
		Case
			when f.clubid = 132 Then 'NatWest'
			when f.clubid = 138 Then 'RBS'
		End as Brand
		, count(*) as Total
		, min (OnlineRegistrationDate) as StartDate
		, max (OnlineRegistrationDate) as EndDate
	from SLC_REPL..FanCredentials fc
	inner join SLC_REPL..fan f 
		on f.id = fc.fanid
	where fc. OnlineRegistrationDate between @StartDate and @EndDateCalc
		and ClubID in (132, 138)
	group by f.ClubID

End