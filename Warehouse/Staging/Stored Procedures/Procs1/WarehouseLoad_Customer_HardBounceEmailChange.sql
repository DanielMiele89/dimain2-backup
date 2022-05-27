
/*
	Author:			Stuart Barnley
	Date:			12-05-2014

	Description:	For customers that have changed their email address since 
					hard bouncing, this will reset the Hardbounce flag.
*/

CREATE Procedure Staging.WarehouseLoad_Customer_HardBounceEmailChange
as
/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'WarehouseLoad_Customer_HardBounceEmailChange',
		TableSchemaName = 'Relational',
		TableName = 'Customer',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'C'
-------------------------------------------------------------------------------
--------------------------Find those who HardBounced---------------------------
-------------------------------------------------------------------------------
if object_id('tempdb..#HB') is not null drop table #HB
select Distinct c.FanID,s.[Group]
into #HB
from Relational.Customer as c
left outer join Relational.SandyAccount_IncCINIDs as s
	on c.FanID = s.FanID and [Group] = '1+2' 
where	c.Unsubscribed = 0 and 
		c.hardbounced = 1 and -- must have already hard bounced
		c.EmailStructureValid = 1 and  
		c.CurrentlyActive = 1 and -- must be active
		s.FanID is null and -- No-one being removed because of project Sandy
		c.Marketablebyemail = 0 and -- Currently not emailable
		c.DeactivatedDate is null and -- not deactivated
		c.OptedOutDate is null -- not opted out
-------------------------------------------------------------------------------
-------------Find those who HardBounced - Latest Date of Bounce----------------
-------------------------------------------------------------------------------
if object_id('tempdb..#HBDate') is not null drop table #HBDate
select Distinct	
		ee.FanID,
		Max(ee.EventDateTime) as HB_Date
Into #HBDate
from Relational.EmailEvent as ee with (nolock)
inner join Relational.EmailEventCode as eec
	on ee.EmailEventCodeID = eec.EmailEventCodeID
inner join #HB as hb
	on ee.FanID = hb.FanID
Where ee.EmailEventCodeID = 702  -- Hard Bounce Event Code
Group by ee.FanID
-------------------------------------------------------------------------------
------------------Find those who changed email after Bounce--------------------
-------------------------------------------------------------------------------
--Find the change of email address entry in the change log
if object_id('tempdb..#NewEmail_Fans') is not null drop table #NewEmail_Fans
Select Distinct n.FanID
Into #NewEmail_Fans
from Archive.Changelog.DataChangeHistory_Nvarchar as n with (nolock)
inner join #HBDate as h
	on n.FanID = h.FanID
inner join Relational.customer as c
	on n.Value = c.Email -- email address must be changed to what it is now
Where	n.TableColumnsID = 2 and -- entry changed must be the email address
		n.[Date] > h.HB_Date and -- changelog entry must be after HardBounce
		hb_Date >= 'Mar 01, 2014' /* This is so we don;t start emailing 
								     someone from to long ago*/
-------------------------------------------------------------------------------
----------------Change HardBounce Value then Marketablebyemail-----------------
-------------------------------------------------------------------------------
--Update Hardbounce and MarketbleByEmail for all those in the previously created list
Update Relational.Customer
Set Hardbounced = 0,
	MarketableByEmail = 1
Where FanID in (Select Fanid from #NewEmail_Fans)

/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'WarehouseLoad_Customer_HardBounceEmailChange' and
		TableSchemaName = 'Relational' and
		TableName = 'Customer' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  staging.JobLog_Temp
Set		TableRowCount = (Select Count(Fanid) from #NewEmail_Fans)
where	StoredProcedureName = 'WarehouseLoad_Customer_HardBounceEmailChange' and
		TableSchemaName = 'Relational' and
		TableName = 'Customer' and
		TableRowCount is null

Insert into staging.JobLog
select [StoredProcedureName],
	[TableSchemaName],
	[TableName],
	[StartDate],
	[EndDate],
	[TableRowCount],
	[AppendReload]
from staging.JobLog_Temp
truncate table staging.JobLog_Temp