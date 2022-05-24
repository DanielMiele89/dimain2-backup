/*
	Author:		Stuart Barnley

	Date:		17th February 2016

	Purpose:	To produce a list of those accounts identified by process in Phase1,
				may not be 100%
	
*/

CREATE Procedure [MI].[Customer_LoyaltyAccountRoughList] (@TableName varchar(200))
WITH EXECUTE AS OWNER
As

Declare @Qry nvarchar(max)

Select * 
Into #Accounts
from 
	(
		select	FanID,
				AccountName1
		from SLC_Report.dbo.FanSFDDailyUploadData_DirectDebit with (nolock)
		Where AccountName1 Like 'Reward%'
		
		Union All

		select	FanID,
				AccountName2
		from SLC_Report.dbo.FanSFDDailyUploadData_DirectDebit with (nolock)
		Where AccountName2 Like 'Reward%'
		
		Union All
		
		select	FanID,
				AccountName3
		from SLC_Report.dbo.FanSFDDailyUploadData_DirectDebit with (nolock)
		Where AccountName3 Like 'Reward%'
	) as a

Set @qry = '
Select a.* 
Into '+@TableName+'
from #Accounts as a
inner join Warehouse.Staging.SLC_Report_DailyLoad_Phase2DataFields as b with (nolock)
	on a.fanid = b.fanid
Where b.LoyaltyAccount = 1'

Exec SP_ExecuteSQL @Qry