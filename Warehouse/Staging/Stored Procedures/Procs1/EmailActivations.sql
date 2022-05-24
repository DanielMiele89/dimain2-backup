
--Use [Warehouse]
CREATE Procedure [Staging].[EmailActivations] (@StartDate date)
As
-------------------------------------------------------------------------------------------------
-------------------------------------Pull Campaign Member Stats----------------------------------
-------------------------------------------------------------------------------------------------
if object_id('tempdb..#CampaignMembers') is not null drop table #CampaignMembers
Select	EmailCampaign_ActivationID,
		CampaignDescription,
		EmailStatus,
		SendDate,
		EndDate,
		Bank,
		Sum(Case
				When Grp = 'Mail' then CustomerCount
				Else 0
			End) as Mail,
		Sum(Case
				When Grp = 'Control' then CustomerCount
				Else 0
			End) as [Control]
into #CampaignMembers
From
(Select	m.EmailCampaign_ActivationID,
		a.CampaignDescription,
		a.EmailStatus,
		Cast(a.SendDate as date) as SendDate,
		Cast(a.EndDate as date) as EndDate,
		Case
			When m.ClubID = 132 then 'Natwest'
			When m.ClubID = 138 then 'RBS'
			Else 'Unknown'
		End as Bank,
		m.Grp,
		Count(m.FanID) as CustomerCount
From Relational.EmailCampaign_Activation as a
Left Outer join Relational.EmailCampaign_Activation_Members as m
	on a.ID = m.EmailCampaign_ActivationID
Where SendDate > @StartDate 
Group by m.EmailCampaign_ActivationID,a.CampaignDescription,a.EmailStatus,a.SendDate,a.EndDate,m.ClubID,m.Grp
) as a
Group by EmailCampaign_ActivationID,CampaignDescription,EmailStatus,SendDate,EndDate,Bank
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
if object_id('tempdb..#CampaignSubscriptions') is not null drop table #CampaignSubscriptions
Select	EmailCampaign_ActivationID,
		Case
			When ClubID = 132 then 'Natwest'
			When ClubID = 138 then 'RBS'
			Else 'Unknown'
		End as Bank,
		Sum(Case
				When Grp = 'Mail' then Pre_EmailActivation
				Else 0
			End) as Pre_EmailActivation_Mail,
		Sum(Case
				When Grp = 'Control' then Pre_EmailActivation
				Else 0
			End) as Pre_EmailActivation_Control,
		Sum(Case
				When Grp = 'Mail' then DayOfSend_Activation
				Else 0
			End) as DayOfSend_Activation_Mail,
		Sum(Case
				When Grp = 'Control' then DayOfSend_Activation
				Else 0
			End) as DayOfSend_Activation_Control,
		Sum(Case
				When Grp = 'Mail' then Post_EmailActivation
				Else 0
			End) as Post_EmailActivation_Mail,
		Sum(Case
				When Grp = 'Control' then Post_EmailActivation
				Else 0
			End) as Post_EmailActivation_Control
into #CampaignSubscriptions
From
(Select	m.EmailCampaign_ActivationID,
		m.ClubID,
		m.Grp,
		Sum(Case
				When c.ActivatedDate < a.SendDate then 1
				Else 0
			End) as Pre_EmailActivation,
		Sum(Case
				When cast(c.ActivatedDate as date) = Cast(a.SendDate as date) then 1
				Else 0
			End) as DayOfSend_Activation,
		Sum(Case
				When cast(c.ActivatedDate as date) Between dateadd(day,1,Cast(a.SendDate as date))  and a.EndDate then 1
				Else 0
			End) as Post_EmailActivation
from Relational.EmailCampaign_Activation as a
Inner Join Relational.EmailCampaign_Activation_Members as m
	on a.ID = m.EmailCampaign_ActivationID
left Outer join Warehouse.relational.Customer as c
	on m.FanID = c.FanID
inner join #CampaignMembers as cm
	on a.ID = cm.EmailCampaign_ActivationID and Case
			When m.ClubID = 132 then 'Natwest'
			When m.ClubID = 138 then 'RBS'
			Else 'Unknown'
		End = cm.Bank
Group by m.EmailCampaign_ActivationID,m.ClubID,m.Grp
) as a
Group by EmailCampaign_ActivationID,
		 Case
			When ClubID = 132 then 'Natwest'
			When ClubID = 138 then 'RBS'
			Else 'Unknown'
		 End
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
Select	m.*,
		Pre_EmailActivation_Mail,
		Pre_EmailActivation_Control,
		DayOfSend_Activation_Mail,
		DayOfSend_Activation_Control,
		Post_EmailActivation_Mail,
		Post_EmailActivation_Control
from #CampaignMembers as m
inner join #CampaignSubscriptions as s
	on	m.EmailCampaign_ActivationID = s.EmailCampaign_ActivationID and
		m.Bank = s.Bank