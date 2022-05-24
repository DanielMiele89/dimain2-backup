/*

	Author:		Stuart Barnley

	Date:		16the September 2016

	Purpose:	This stored procedure is used to find the campaign keys for the latest MyRewards email
				send and update the warehouse.

	Parameters:	@Update - if this is set to "0" it displays what it believes is the correct information,
						  whereas if "1" it updates the Relational.CampaignLionSendIDs table and displays
						  the update.
*/

CREATE Procedure [Staging].[WarehouseLoad_SmartFocusCampaignKey_Update]
with Execute as Owner
As

Declare @Update bit,@RowCount int
Set @Update = 1
/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'WarehouseLoad_SmartFocusCampaignKey_Update',
		TableSchemaName = 'Relational',
		TableName = 'CampaignLionSendIDs',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'A'


/*---------------------------------------------------------------------------*/
-------------------Produce List of new Campaigns to be added-------------------
/*---------------------------------------------------------------------------*/

Select  e.CampaignKey,
		LionSendID = Cast(right(Left(QueryName,28),3) as int),
		EmailType = 'H',
		Reference = Cast(Round(Cast(Datediff(day,'2016-07-22',SendDate) as real)/7,0,0)+236 as varchar(4))+'H',
		[HardCoded_OfferFrom] = Cast(NULL as int),
		[HardCoded_OfferTo] = Cast(NULL as int),
		[EmailName] = Cast(NULL as varchar(100)),
		ClubID = Case
					When CampaignName Like '%NatWest%' then 132
					Else 138
					End,
		TrueSolus = 0
Into #NewRows
from SLC_Report.dbo.EmailCampaign as e with (nolock)
left outer join [Relational].[CampaignLionSendIDs] as f with (nolock)
	on e.campaignkey = f.campaignkey
Where CampaignName Like '%Newsletter_LSID[0-9][0-9][0-9]_%' and CampaignName not like 'TEST%' and
		SendDate > '2016-07-22' and
		f.campaignkey is null

---------------------------------------

If @Update = 0
Begin
		/*---------------------------------------------------------------------------*/
		-------------------------------Review List-------------------------------------
		/*---------------------------------------------------------------------------*/

		Select * 
		from #NewRows as a
		inner join slc_report.dbo.EmailCampaign as EC with (nolock)
			on a.CampaignKey = EC.CampaignKey

End

--------------------------------------

If @Update = 1
Begin
		/*---------------------------------------------------------------------------*/
		-------------------------------Final Insert------------------------------------
		/*---------------------------------------------------------------------------*/
		INSERT INTO Relational.CampaignLionSendIDs
		SELECT	*
		FROM #NewRows
		SET @RowCount = @@ROWCOUNT

		--/*---------------------------------------------------------------------------*/
		---------------------------------Final Checking--------------------------------
		--/*---------------------------------------------------------------------------*/
		--SELECT	top (@RowCount) *
		--FROM Relational.CampaignLionSendIDs cls with (nolock)
		--INNER JOIN SLC_Report.dbo.EmailCampaign as ec with (nolock)
		--	  ON cls.CampaignKey = ec.CampaignKey
		--ORDER BY LionSendID Desc

		------------------------------------------------------------------------------
		--------------------------------------Drop tables-----------------------------
		------------------------------------------------------------------------------
End 

Drop table #NewRows

/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'WarehouseLoad_SmartFocusCampaignKey_Update' and
		TableSchemaName = 'Relational' and
		TableName = 'CampaignLionSendIDs' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  staging.JobLog_Temp
Set		TableRowCount = @RowCount
where	StoredProcedureName = 'WarehouseLoad_SmartFocusCampaignKey_Update' and
		TableSchemaName = 'Relational' and
		TableName = 'CampaignLionSendIDs' and
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

TRUNCATE TABLE staging.JobLog_Temp






  
