CREATE Procedure [Staging].[SSRS_R0109_CustomerActivations_Vs_MarketableByEmail] (@StartDate Date,@EndDate Date)
as 
Select	ClubID,
		ActivatedDate,
		Reason,
		Count(*)
From
(
Select  
		FanID,
		ClubID,
		Case
			When ActivatedOffline = 1 and c.EmailStructureValid = 0 then 'Bad/no email address and activated offline'
			When ActivatedOffline = 1 then 'Activated Offline'
			When Unsubscribed = 1 and ActivatedOffline = 0 and EmailStructureValid = 1 then 'Unsubscribed'
			When ActivatedOffline = 0 and EmailStructureValid = 0 then 'Bad Email'
			When Len(PostCode) < 3 then 'Bad Postcode'
			When Hardbounced = 1 then 'Hardbounced'
			Else 'Other'
		End as Reason,
		ActivatedDate

From Relational.customer as c
where	--marketablebyemail = 0 and
		activateddate Between @StartDate and @EndDate and
		CurrentlyActive = 1
) as a
Group by ClubID,
		ActivatedDate,
		Reason