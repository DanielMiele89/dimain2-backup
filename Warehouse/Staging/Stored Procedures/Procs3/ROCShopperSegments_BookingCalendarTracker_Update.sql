
CREATE PROCEDURE [Staging].[ROCShopperSegments_BookingCalendarTracker_Update] @EmailDate date
As 
Begin

/******************************************************************		
		Delete blank rows 
******************************************************************/
Delete from Staging.ROCShopperSegments_BookingCalendarTracker
where BookingCalendarInfo is null


/******************************************************************		
		 Get CSRef from booking calendar string
******************************************************************/
Update x
Set ClientServicesRef = 
		Case 
			when SUBSTRING(BookingCalendarInfo, charindex(' - ', BookingCalendarInfo)+3, 6) not like '%[A-Z]%[0-9]%' then NULL 
			Else SUBSTRING(BookingCalendarInfo, charindex(' - ', BookingCalendarInfo)+3, 6)
			End 
from Staging.ROCShopperSegments_BookingCalendarTracker x


/******************************************************************		
		Update rows with ALS selections 
******************************************************************/
Update x
Set Selectioncoded = 'ALS'
from Staging.ROCShopperSegments_BookingCalendarTracker x
inner join Selections.ROCShopperSegment_PreSelection_ALS als
	on x.ClientServicesRef = als.ClientServicesRef
	and als.EmailDate = @EmailDate

--Update x
--Set Selectioncoded = 'ALS - Ended'
--from Staging.ROCShopperSegments_BookingCalendarTracker x
--inner join staging.ROCShopperSegment_PreSelection_ALS als
--	on x.ClientServicesRef = als.ClientServicesRef
--	and als.EmailDate < @EmailDate
--Where CampaignName not like '%Launch%'

/******************************************************************		
		Update rows with old selections
******************************************************************/
Update x
Set Selectioncoded = 'Old'
from Staging.ROCShopperSegments_BookingCalendarTracker x
inner join staging.ROCShopperSegment_PreSelection old
	on x.ClientServicesRef = old.ClientServicesRef
	and old.EmailDate = @EmailDate

--Update x
--Set Selectioncoded = 'Old - Ended'
--from Staging.ROCShopperSegments_BookingCalendarTracker x
--inner join staging.ROCShopperSegment_PreSelection old
--	on x.ClientServicesRef = old.ClientServicesRef
--	and old.EmailDate < @EmailDate
--Where CampaignName not like '%Launch%'

Exec Staging.ROCShopperSegments_BookingCalendarTracker_SendEmail

End