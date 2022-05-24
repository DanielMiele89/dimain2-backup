/*
	Author:			Stuart Barnley

	Date:			24th February 2016

	Purpose:		To retrospectively provide data for the SFD Datily load, where it has run
					but the emails were not sent
*/

CREATE PROCEDURE [Staging].[SLC_Report_DailyLoad_RetroRun_DataExists] (@SDate Date, @EDate Date)

As

Declare @DateText varchar(10),
		@Qry nvarchar(max),
		@StartDate Date,
		@EndDate Date

Set @DateText = Convert(Varchar,getdate(), 112) -- Date turn to text for table name

Set @StartDate = @SDate
Set @EndDate = @EDate

select @StartDate, @EndDate


--Set @Qry = '
--if object_id('+Char(39)+'Warehouse.InsightArchive.MyRewards_FirstEarnDD_'+@DateText+Char(39)+') is not null 
--														drop table ' + 'Warehouse.InsightArchive.MyRewards_FirstEarnDD_'+@DateText+'
--Select	f.EMAIL,
--		FIRSTEARNTYPE = ''direct debit frontbook'',
--		CAST(Dateadd(day,DATEDIFF(dd, 0, GETDATE())-1,0) as DATE) as FIRSTEARNDATE,
--		a.FanID as [Customer ID],
--	    a.AccountName as MyRewardAccount,
--		FirstEarnDate [ActualFirstEarnDate]
--Into Warehouse.InsightArchive.MyRewards_FirstEarnDD_'+@DateText+'
--from Warehouse.Staging.Customer_FirstEarnDDPhase2 as a
--inner join slc_report.dbo.fan as f
--	on a.FanID = f.ID
--Where FirstEarnDate between 
--	'''+Convert(Varchar,DateAdd(day,-1,@StartDate), 107)+''' and '''+Convert(Varchar,Dateadd(day,-1,@EndDate), 107)+''' and
--		Len(f.email) >= 8 and
--		f.email like ''%@%.%'''

-- --Select @Qry
--Exec SP_ExecuteSQL @Qry

--Set @Qry = '
--if object_id('+Char(39)+'Warehouse.InsightArchive.MyRewards_FirstEarn_'+@DateText+Char(39)+') is not null 
--														drop table ' + 'Warehouse.InsightArchive.MyRewards_FirstEarn_'+@DateText+'
--Select	f.EMAIL,
--		a.FIRSTEARNTYPE,
--		Cast(Dateadd(day,DATEDIFF(dd, 0, GETDATE())-1,0) as DATE) as FIRSTEARNDATE,
--		a.FanID as [Customer ID],
--	    a.FirstEarnValue,
--		FirstEarnDate [ActualFirstEarnDate]
--INTO	Warehouse.InsightArchive.MyRewards_FirstEarn_'+@DateText+'
--from Warehouse.Staging.Customers_Passed0GBP as a
--inner join slc_report.dbo.fan as f
--	on a.FanID = f.ID
--Left outer join Warehouse.InsightArchive.MyRewards_FirstEarnDD_'+@DateText+' as b
--	on a.fanid = b.[Customer ID]
--Where	a.Date between '''+Convert(Varchar,DateAdd(day,-1,@StartDate), 107)+''' and '''+Convert(Varchar,Dateadd(day,-1,@EndDate), 107)+''' and
--		b.[Customer ID] is null AND
--		a.FirstEarnType <> '''' and
--		Len(f.email) >= 8 and
--		f.email like ''%@%.%'''


		

--Exec SP_ExecuteSQL @Qry

--Set @Qry = '
--if object_id('+Char(39)+'Warehouse.InsightArchive.MyRewards_Reached5GBP_'+@DateText+Char(39)+') is not null 
--														drop table ' + 'Warehouse.InsightArchive.MyRewards_Reached5GBP_'+@DateText+'
--Select a.FanID as [Customer ID],
--	   f.Email,
--	   a.Reached [ActualDateReached],
--	   Dateadd(day,DATEDIFF(dd, 0, GETDATE())-0,0) as Reach5GBP
--Into   Warehouse.InsightArchive.MyRewards_Reached5GBP_'+@DateText+'
--from [Warehouse].[Relational].[Customers_Reach5GBP] as a
--inner join slc_report.dbo.fan as f
--	on a.FanID = f.ID
--Where a.Reached between '''+Convert(Varchar,@StartDate, 107)+''' and '''+Convert(Varchar,@EndDate, 107)+''' and
--		a.Redeemed = 0 and
--		Len(f.email) >= 8 and
--		f.email like ''%@%.%'''

--Exec SP_ExecuteSQL @Qry

--Set @Qry = '

--if object_id('+Char(39)+'Warehouse.InsightArchive.MyRewards_Day65AccountNames_'+@DateText+Char(39)+') is not null 
--														drop table ' + 'Warehouse.InsightArchive.MyRewards_Day65AccountNames_'+@DateText+'
--Select	a.FanID as [Customer ID],
--		f.Email,
--		a.AccountNo as Day65AccountNo,
--		Replace(a.AccountName,'' account'','''') as Day65AccountName
--Into Warehouse.InsightArchive.MyRewards_Day65AccountNames_'+@DateText+'
--from
--(
--Select *,
--		ROW_NUMBER() OVER(PARTITION BY FanID ORDER BY BankAccountID ASC) AS RowNo
--from Staging.Customer_DDNotEarned
--Where ChangeDate Between DATEADD(dd, -65, DATEDIFF(dd, 0, '''+Convert(Varchar,@StartDate, 107)+''')) and DATEADD(dd, -65, DATEDIFF(dd, 0, '''+Convert(Varchar,@EndDate, 107)+'''))
--) as a
--inner join slc_report.dbo.fan as f
--	on a.fanid = f.id
--Where RowNo = 1 and
--	  	Len(f.email) >= 8 and
--		f.email like ''%@%.%'''


--Exec SP_ExecuteSQL @Qry


--Declare @StartDateDOB Date, @EndDateDOB Date

--Set @StartDateDOB = (Select DATEADD(YEAR,-(DATEPART(YEAR,@StartDate)-1900),@StartDate))
--Set @EndDateDOB = (Select DATEADD(YEAR,-(DATEPART(YEAR,@EndDate)-1900),@EndDate))

--Set @Qry = '
--if object_id('+Char(39)+'Warehouse.InsightArchive.MyRewards_BirthdayCodes_'+@DateText+Char(39)+') is not null 
--														drop table ' + 'Warehouse.InsightArchive.MyRewards_BirthdayCodes_'+@DateText+'
--Select	FanID as [Customer ID],
--		Email as Email,
--		DATEADD(YEAR,-(DATEPART(YEAR,c.DOB)-1900),Cast(c.DOB as date)) ActualDOB, 
--		DATEADD(YEAR,-(DATEPART(YEAR,GetDate() )-1900),Cast(GetDate() as date)) as DOB
--Into Warehouse.InsightArchive.MyRewards_BirthdayCodes_'+@DateText+'
--From Warehouse.Relational.Customer as c
--Where	MarketableByEmail = 1 and
--		DATEADD(YEAR,-(DATEPART(YEAR,DOB)-1900),c.DOB) BETWEEN '''+Convert(Varchar,@StartDateDOB, 107)+''' and '''+Convert(Varchar,@EndDateDOB, 107)+'''
--'

--Exec SP_ExecuteSQL @Qry

Set @Qry = '
if object_id('+Char(39)+'Warehouse.InsightArchive.MyRewards_WelcomeCC_'+@DateText+Char(39)+') is not null 
														drop table ' + 'Warehouse.InsightArchive.MyRewards_WelcomeCC_'+@DateText+'
Select  a.EMAIL,
		Case
			When ActivatedDate >= P.AdditionDate then ''W8''
			Else ''W7''
		End as WELCOMEEMAILCODE,
		f.FanID as [Customer ID]
Into Warehouse.InsightArchive.MyRewards_WelcomeCC_'+@DateText+'
FROM SLC_Report..FanSFDDailyUploadData AS F WITH (NOLOCK)
INNER JOIN SLC_Report..Pan AS P WITH (NOLOCK) 
		ON P.CompositeID = F.CompositeID
INNER JOIN SLC_Report..PaymentCard AS PC WITH (NOLOCK) 
		ON P.PaymentCardID = PC.ID
inner join SLC_Report..Fan as a WITH (Nolock)
		on f.fanid = a.id
Where	CONVERT(DATE, P.AdditionDate) Between '''+Convert(Varchar,DateAdd(day,-1,@StartDate), 107)+''' and '''+Convert(Varchar,Dateadd(day,-1,@EndDate), 107)+''' and
		RemovalDate is null and
		PC.CardTypeID = 1 and
		Len(a.email) >= 8 and
		a.email like ''%@%.%'''


Exec SP_ExecuteSQL @Qry


--Set @qry = 
--'
--if object_id('+Char(39)+'Warehouse.InsightArchive.MyRewards_HomeMover_'+@DateText+Char(39)+') is not null 
--														drop table ' + 'Warehouse.InsightArchive.MyRewards_HomeMover_'+@DateText+'

--Select	EMAIL,
--		1 as HOMEMOVER ,
--		a.FanID as [Customer ID]
--Into Warehouse.InsightArchive.MyRewards_HomeMover_'+@DateText+'
--From (
--		Select FanID
--		from Warehouse.[Relational].[Homemover_Details]
--		Where Len(NewPostcode) >= 5 and
--			  Len(OldPostcode) >= 5
--		Group by FanID
--			Having Max(LoadDate) Between '''+Convert(Varchar,DateAdd(day,-1,@StartDate), 107)+''' and '''+Convert(Varchar,Dateadd(day,-1,@EndDate), 107)+'''
--	 ) as a
--inner join warehouse.relational.customer as c
--	on	a.FanID = c.FanID and
--		MarketableByEmail = 1
--		'

--Exec SP_ExecuteSQL @Qry

--Set @qry = '
--if object_id('+Char(39)+'Warehouse.InsightArchive.MyRewards_NotRedeemed_'+@DateText+Char(39)+') is not null 
--														drop table ' + 'Warehouse.InsightArchive.MyRewards_NotRedeemed_'+@DateText+'
--Select	a.FanID,
--		email,
--		Cast(Dateadd(day,-45,'''+Convert(Varchar,@StartDate, 107)+''') as date) ActualReach5GBP,
--		Cast(Dateadd(day,-45,GetDate()) as date)  Reach5GBP
--Into Warehouse.InsightArchive.MyRewards_NotRedeemed_'+@DateText+'
--from [Warehouse].[Relational].[Customers_Reach5GBP] as a
--inner join warehouse.relational.customer as c
--	on a.fanid = c.fanid
--Where Reached Between Dateadd(day,-45,'''+Convert(Varchar,@StartDate, 107)+''') and DateAdd(day,-45,'''+Convert(Varchar,@EndDate, 107)+''') and
--	  MarketableByEmail = 1 and
--	  a.redeemed = 0
--Union All
--Select	a.FanID,
--		email,
--		Cast(Dateadd(day,-90,'''+Convert(Varchar,@StartDate, 107)+''') as date) ActualReach5GBP,
--		Cast(Dateadd(day,-90,GetDate()) as date)  Reach5GBP
--from [Warehouse].[Relational].[Customers_Reach5GBP] as a
--inner join warehouse.relational.customer as c
--	on a.fanid = c.fanid
--Where Reached Between Dateadd(day,-90,'''+Convert(Varchar,@StartDate, 107)+''') and DateAdd(day,-90,'''+Convert(Varchar,@EndDate, 107)+''') and
--	  MarketableByEmail = 1 and
--	  a.redeemed = 0
--Union All
--Select	a.FanID,
--		email,
--		Cast(Dateadd(day,-120,'''+Convert(Varchar,@StartDate, 107)+''') as date) ActualReach5GBP,
--		Cast(Dateadd(day,-120,GetDate()) as date)  Reach5GBP
--from [Warehouse].[Relational].[Customers_Reach5GBP] as a
--inner join warehouse.relational.customer as c
--	on a.fanid = c.fanid
--Where Reached Between Dateadd(day,-120,'''+Convert(Varchar,@StartDate, 107)+''') and DateAdd(day,-120,'''+Convert(Varchar,@EndDate, 107)+''') and
--	  MarketableByEmail = 1 and
--	  a.redeemed = 0'

--Exec sp_ExecuteSQL @Qry
