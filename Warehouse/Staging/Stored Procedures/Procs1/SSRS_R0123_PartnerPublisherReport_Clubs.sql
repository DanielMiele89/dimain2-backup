CREATE Procedure Staging.SSRS_R0123_PartnerPublisherReport_Clubs
As

Select 0 as ClubID,'ALL' as ClubName
Union All
Select	ID as ClubID,
		Name as ClubName
From SLC_Report.dbo.Club as c
Where ID in (132,138)
Union All
Select *
From nFI.Relational.Club as c