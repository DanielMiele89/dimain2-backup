/*
	Author:			Stuart Barnley
	Date:			27th March 2014
	Title:			Activation Emails Data Load

	Description:	This stored procedure gives you a quick way to load Activation email data to the relevent tables

	Notes:			This does not include adding IronOffer  or Control group entries

*/

CREATE Procedure Staging.ActivationEmails_DataLoad 
		@SendDate datetime,
		@EmailStatus int,
		@CampaignDescription as varchar(200),
		@Tablename varchar(300)
As 		
Declare @Qry nvarchar(Max)
------------------------------------------------------------------------------------------------------------
-----------------------------Add Entry to EmailCampaigns_Activations table----------------------------------
------------------------------------------------------------------------------------------------------------
Insert into [Relational].[EmailCampaign_Activation]
select	@SendDate as SendDate,
		@CampaignDescription as CampaignDescription,
		Case
			When @EmailStatus = 1 then 'Sent'
			Else 'Open'
		End as EmailStatus,
		Dateadd(second,-1,Dateadd(day,+15,@sendDate)) as EndDate
-----------------------------------------------------------------------------------------------------------
----------------------------------------EmailCampaign_Activation_Members table-----------------------------
-----------------------------------------------------------------------------------------------------------
Set @Qry = '
Insert into [Relational].[EmailCampaign_Activation_Members]
Select (Select	Max(ID) from [Relational].[EmailCampaign_Activation]) as EmailCampaign_ActivationID,
				a.FanID,
				f.ClubID,
				''Mail'' as Grp
From ' + @TableName +' as a
inner join slc_report.dbo.Fan as f
	on a.fanid = f.id'

Exec sp_ExecuteSQL @Qry
