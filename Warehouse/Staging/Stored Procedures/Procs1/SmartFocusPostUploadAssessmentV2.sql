--declare @Tablename nvarchar(200),@Qry nvarchar(max),@DataDate date,@EmailType varchar(1),@IronOfferString Varchar(100)
--Set @Tablename = replace(replace('sandbox.[Stuart].[RBS_Solus_20131206]','[',''),']','')
--Set @DataDate = 'Dec 06, 2013'
--Set @EmailType = 'S'
--Set @IronOfferString = '123456789'
CREATE Procedure [Staging].[SmartFocusPostUploadAssessmentV2]
			(@Tablename nvarchar(200),
			 @DataDate date,
			 @EmailType varchar(1),
			 @IronOfferString Varchar(100))
As
Begin

Declare @Qry nvarchar(max)
if object_id('tempdb..##SB_T1') is not null drop table ##SB_T1
------------------------------------------------------------------------------------------------
----------------------------------Delete Duplicates from tables---------------------------------
------------------------------------------------------------------------------------------------
--This Section removes previous runs of the data if run against the same data table
Delete from Warehouse.[Staging].[PostSFDEmailEvaluation_CJStageCounts] Where TableName = @TableName
Delete from Warehouse.[Staging].[PostSFDEmailEvaluation_CJStageTodayVsYesterday] Where TableName = @TableName
Delete from Warehouse.[Staging].[PostSFDEmailEvaluation_CJStageMOTWeekNos] Where TableName = @TableName
Delete From Warehouse.[Staging].[PostSFDEmailEvaluation_CJStageTodayVsYesterday_SampleMovers] Where TableName = @TableName
Delete From Warehouse.staging.PostSFDEmailEvaluation_IronOfferAssessment Where TableName = @TableName
------------------------------------------------------------------------------------------------
-----------------------------------Assess Balances at CJ Level----------------------------------
------------------------------------------------------------------------------------------------
/*Group people by Shortcode and balances*/
Set @Qry = '
Use Sandbox
Select	'''+ @TableName+''' as TableName,
		Cast('''+ convert(varchar, @DataDate, 107)+''' as date) as DataDate,
		LionSendID, 
		ClubID,
		left(CustomerJourneyStatus,2) as Shortcode,
		Case
			When cast(ClubCashPending as real) <= 0 then ''£0 or less''
			When cast(ClubCashPending as real) Between 0.01 and 4.99 then ''Between £0.01 and £4.99''
			When cast(ClubCashPending as real) >= 5 then ''£5+''
			Else ''''
		End as Pending,
		Case
			When Cast(ClubCashAvailable as real) <= 0 then ''£0 or less''
			When cast(ClubCashAvailable as real) Between 0.01 and 4.99 then ''Between £0.01 and £4.99''
			When cast(ClubCashAvailable as real) >= 5 then ''£5+''
			Else ''''
		End as Available,
		Count(*) as CustomerCount
Into ##SB_T1
from ' + @TableName + '
Group by left(CustomerJourneyStatus,2),
		Case
			When cast(ClubCashPending as real) <= 0 then ''£0 or less''
			When cast(ClubCashPending as real) Between 0.01 and 4.99 then ''Between £0.01 and £4.99''
			When cast(ClubCashPending as real) >= 5 then ''£5+''
			Else ''''
		End,
		Case
			When Cast(ClubCashAvailable as real) <= 0 then ''£0 or less''
			When cast(ClubCashAvailable as real) Between 0.01 and 4.99 then ''Between £0.01 and £4.99''
			When cast(ClubCashAvailable as real) >= 5 then ''£5+''
			Else ''''
		End,
		LionSendID, 
		ClubID
Order By Case
			When left(CustomerJourneyStatus,2) = ''M1'' then 1
			When left(CustomerJourneyStatus,2) = ''M2'' then 2
			When left(CustomerJourneyStatus,2) = ''M3'' then 3
			When left(CustomerJourneyStatus,2) = ''SL'' then 4
			When left(CustomerJourneyStatus,2) = ''SH'' then 5
			When left(CustomerJourneyStatus,2) = ''RL'' then 6
			When left(CustomerJourneyStatus,2) = ''RH'' then 7
		  End
'
--select @Qry
Exec sp_sqlexec @Qry

--select * from sandbox.[Stuart].[RBS_Solus_20131121]
--Where CustomerJourneyStatus = 'm3N' and ClubCashAvailable < 5
------------------------------------------------------------------------------------------------------------
------------------------------------------Highlight known errors--------------------------------------------
------------------------------------------------------------------------------------------------------------
--Create a flag to indicate if balances and Shortcodes are not compatible (i.e. MOT3 with <£5 avilable cashback)
Insert into Warehouse.[Staging].[PostSFDEmailEvaluation_CJStageCounts]
Select *,
		Case
			When Shortcode = 'M1' and (Available <> '£0 or less' or Pending <> '£0 or less') then 'Yes'
			When Shortcode = 'M2' and Available = '£5+' then 'Yes'
			When Shortcode = 'M3' and Available <> '£5+' then 'Yes'
			Else 'No'
		End as Problems
from ##SB_T1

Set @Qry = '
Select	Count(distinct [Customer ID]) as DistictCustomersInFile,
		Count(*) as RecordsInFile from ' + @TableName

Exec sp_sqlexec @Qry
------------------------------------------------------------------------------------------------------------
-------------------------Assessment by ClubID for Disabled, Emailable and Missing Postcodes-----------------
------------------------------------------------------------------------------------------------------------
--Look at how many of the uploaded people are deactivated or unsubscribed
Set @Qry = '
Select	c.ClubID,
		Count(Distinct C.FanID),
		Sum(Case
				When c.CurrentlyActive <> 1 then 1
				Else 0
			End) as Deactivated,
		Sum(Case
				When c.Marketablebyemail <> 1 then 1
				Else 0
			End) as NotEmailable,
		Sum(Case
				When len(c.Postcode) < 3 then 1
				Else 0
			End) as MissingPostcode,
		''In Customer Table Records''
from Warehouse.relational.customer as c
inner join ' + @TableName + ' as d
	on c.fanid = d.[Customer id]
Group by c.ClubID'

Exec sp_sqlexec @Qry
------------------------------------------------------------------------------------------------------------
---------------------Check whether all these records are on the LionSendComponent table---------------------
------------------------------------------------------------------------------------------------------------

Set @Qry = '
Select	Count(Distinct c.FanID),
		lsc.LionSendID,
		''In LSC and being emailed''
from ' + @TableName + ' as d
inner join Warehouse.relational.customer as c
	on d.[Customer id] = c.FanID
inner join warehouse.lion.nominatedlionsendcomponent as lsc
	on c.CompositeID = lsc.CompositeID and lsc.LionSendID = d.LionSendID
Group by lsc.LionSendID'
Exec sp_sqlexec @Qry
------------------------------------------------------------------------------------------------------------
----------------------Check numbers for the original upload to LionSendComponent table----------------------
------------------------------------------------------------------------------------------------------------
Set @Qry = '
Select 	LionSendID,
		Count(*) as CustomerCount,
		Sum(Deactivated) as Deactivated,
		Sum(NotEmailable) as NotEmailable,
		Sum(MissingPostcode) as MissingPostcode
 From
(Select	c.FanID,
		lsc.LionSendID,
		Max(Case
				When c.CurrentlyActive <> 1 then 1
				Else 0
			End) as Deactivated,
		Max(Case
				When c.Marketablebyemail <> 1 then 1
				Else 0
			End) as NotEmailable,
		Max(Case
				When len(c.Postcode) < 3 then 1
				Else 0
			End) as MissingPostcode,
		''In LionSendComponent'' as [Type]
from --Warehouse.relational.LionSendComponent as lsc
	  warehouse.lion.nominatedlionsendcomponent as lsc
Inner join warehouse.relational.customer as c
	on lsc.compositeid = c.compositeid
Where lionSendID in (select LionsendID From ' + @TableName + ')
Group by c.FanID,
		lsc.LionSendID
) as a
Group by LionSendID
'

--Select @Qry
Exec sp_sqlexec @Qry
-------------------------------------------------------------------------------------------
------------------------Customer Journey Transitions since Yesterday-----------------------
-------------------------------------------------------------------------------------------
Set @Qry = '
Insert into Warehouse.[Staging].[PostSFDEmailEvaluation_CJStageTodayVsYesterday]
Select	'''+ @TableName+''' as TableName,
		Left(cj.ShortCode,2) as Shortcode_Yesterday,
		Left(d.CustomerJourneyStatus,2) as Shortcode_Today,
		Count(*) as CustomerCount
from Warehouse.relational.CustomerJourney as cj
inner join ' + @TableName + ' as d
	on cj.FanID = d.[Customer ID] and cj.EndDate is null
Group by Left(cj.ShortCode,2),Left(d.CustomerJourneyStatus,2)
Order By Case
			When left(cj.Shortcode,2) = ''M1'' then 1
			When left(cj.Shortcode,2) = ''M2'' then 2
			When left(cj.Shortcode,2) = ''M3'' then 3
			When left(cj.Shortcode,2) = ''SL'' then 4
			When left(cj.Shortcode,2) = ''SH'' then 5
			When left(cj.Shortcode,2) = ''RL'' then 6
			When left(cj.Shortcode,2) = ''RH'' then 7
		  End,
		  Case
		  When left(d.CustomerJourneyStatus,2) = ''M1'' then 1
			When left(d.CustomerJourneyStatus,2) = ''M2'' then 2
			When left(d.CustomerJourneyStatus,2) = ''M3'' then 3
			When left(d.CustomerJourneyStatus,2) = ''SL'' then 4
			When left(d.CustomerJourneyStatus,2) = ''SH'' then 5
			When left(d.CustomerJourneyStatus,2) = ''RL'' then 6
			When left(d.CustomerJourneyStatus,2) = ''RH'' then 7
		  End
'

Exec sp_sqlexec @Qry
-------------------------------------------------------------------------------------------
------------------------Pull off list of transitioning customers---------------------------
-------------------------------------------------------------------------------------------
Set @Qry = '
Insert into Warehouse.[Staging].[PostSFDEmailEvaluation_CJStageTodayVsYesterday_SampleMovers]
Select	'''+ @TableName+''' as TableName,
		ShortCode_Yesterday,
		ShortCode_Today,
		FanID
from
(Select	Left(cj.ShortCode,2) as ShortCode_Yesterday,
		Left(d.CustomerJourneyStatus,2) as Shortcode_Today,
		d.[Customer id] as FanID,
		ROW_NUMBER() OVER(PARTITION BY Left(cj.ShortCode,2),Left(d.CustomerJourneyStatus,2) ORDER BY NewID() DESC) AS RowNo
from Warehouse.relational.CustomerJourney as cj
inner join ' + @TableName + ' as d
	on cj.FanID = d.[Customer ID]
Where Left(cj.ShortCode,2) <> Left(d.CustomerJourneyStatus,2) and cj.EndDate = dateadd(day,-1,cast(getdate() as date))
) as a
Where RowNo <= 3
Order by ShortCode_Yesterday,ShortCode_Today
'

Exec sp_sqlexec @Qry
-------------------------------------------------------------------------------------------
---------------------------------Week No for MOT checks------------------------------------
-------------------------------------------------------------------------------------------
Set @Qry = '
Insert into Warehouse.Staging.PostSFDEmailEvaluation_CJStageMOTWeekNos
Select '''+ @TableName+''' as TableName,
		LionSendID, 
		Left(CustomerjourneyStatus,2) as Shortcode,
		Case
			When Left(CustomerjourneyStatus,2) = ''M1'' then [MOT1-week]
			When Left(CustomerjourneyStatus,2) = ''M2'' then [MOT2-week]
			When Left(CustomerjourneyStatus,2) = ''M3'' then [MOT3-week]
			Else NULL
		End as WeekNo,
		Count(*),
		Case
			When '''+@EmailType+''' = ''S'' then ''Solus''
			Else ''Non-Solus''
		End as EmailType
from ' +@TableName + '
Group by LionSendID, 
		Left(CustomerjourneyStatus,2),
		Case
			When Left(CustomerjourneyStatus,2) = ''M1'' then [MOT1-week]
			When Left(CustomerjourneyStatus,2) = ''M2'' then [MOT2-week]
			When Left(CustomerjourneyStatus,2) = ''M3'' then [MOT3-week]
			Else NULL
		End'

Exec sp_ExecuteSQL @Qry
-------------------------------------------------------------------------------------------
---------------------------------Email'ees on ironOffers------------------------------------
-------------------------------------------------------------------------------------------
Set @Qry = '
Insert Into Warehouse.staging.PostSFDEmailEvaluation_IronOfferAssessment
Select *
From
(Select	'''+ @TableName+''' as TableName,
		LionSendID,
		Case
			When '''+@EmailType+''' = ''S'' then ''Solus''
			Else ''Non-Solus''
		End as EmailType,
		''Nominated Targeted'' as TableChecked,
		nio.IronOfferID,
		Count(*) as CustomerCount
From ' + @Tablename + ' as a
inner join warehouse.relational.customer as c
	on a.[customer id] = c.fanid
inner join warehouse.[iron].[NominatedOfferMember] as nio
	on	C.[CompositeID] = nio.CompositeID and
		IronOfferID in (' + @IronOfferString + ')
Group by nio.IronOfferID,LionSendID

Union All

Select	'''+ @TableName+''' as TableName,
		LionSendID,
		Case
			When '''+@EmailType+''' = ''S'' then ''Solus''
			Else ''Non-Solus''
		End as EmailType,
		''Nominated Trigger'' as TableChecked,
		nio.IronOfferID,
		Count(*) as CustomerCount

From ' + @Tablename + ' as a
inner join warehouse.relational.customer as c
	on a.[customer id] = c.fanid
inner join warehouse.[iron].[TriggerOfferMember] as nio
	on	C.[CompositeID] = nio.CompositeID and
		IronOfferID in (' + @IronOfferString + ')
Group by nio.IronOfferID,LionSendID
Union all
Select	'''+ @TableName+''' as TableName,
		LionSendID,
		Case
			When '''+@EmailType+''' = ''S'' then ''Solus''
			Else ''Non-Solus''
		End as EmailType,
		''IronOfferMember'' as TableChecked,
		iom.IronOfferID,
		Count(*) as CustomerCount
From ' + @Tablename + ' as a
inner join warehouse.relational.customer as c
	on a.[customer id] = c.fanid
inner join warehouse.Relational.ironoffermember as iom
	on	C.[CompositeID] = iom.CompositeID and
		IronOfferID in (' + @IronOfferString + ')
Group by iom.IronOfferID,LionSendID
) as a
'

Exec sp_executeSQL @Qry

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------

Set @Qry = '
Select * from
(select rbs.[Customer ID],
		Max(Case
			When Cast(rbs.Offer1 as int) = lsc.ItemID and ItemRank = 1 then ''Yes''
			Else ''No''
		End) as Offer1,
		Max(Case
			When Cast(rbs.Offer2 as int) = lsc.ItemID and ItemRank = 2 then ''Yes''
			Else ''No''
		End) as Offer2,
		Max(Case
			When Cast(rbs.Offer3 as int) = lsc.ItemID and ItemRank = 3 then ''Yes''
			Else ''No''
		End) as Offer3,
		Max(Case
			When Cast(rbs.Offer4 as int) = lsc.ItemID and ItemRank = 4 then ''Yes''
			Else ''No''
		End) as Offer4,
		Max(Case
			When Cast(rbs.Offer5 as int) = lsc.ItemID and ItemRank = 5 then ''Yes''
			Else ''No''
		End) as Offer5,
		Max(Case
			When Cast(rbs.Offer6 as int) = lsc.ItemID and ItemRank = 6 then ''Yes''
			Else ''No''
		End) as Offer6,
		Max(Case
			When Cast(rbs.Offer7 as int) = lsc.ItemID and ItemRank = 7 then ''Yes''
			Else ''No''
		End) as Offer7
from ' + @TableName + ' as rbs
inner join warehouse.relational.customer as c with (nolock)
	on rbs.[Customer id] = c.fanid
inner join warehouse.Lion.nominatedlionsendcomponent as lsc
	on	c.[CompositeID] = lsc.CompositeID and
		rbs.lionsendid = lsc.lionsendid
Group by rbs.[Customer ID]
) as a
Where Offer1 = ''No'' or Offer2 = ''No'' or Offer3 = ''No'' or Offer4 = ''No'' or Offer5 = ''No'' or Offer6 = ''No'' or Offer7 = ''No''
'

Exec sp_ExecuteSQL @Qry

End
