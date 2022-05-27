Create Procedure [Staging].[SSRS_R0130_DisplayRetailer_Tracking_Validation]
as

Update b
Set Trackable = Case
					When RewardTrackable = 0 then 'No'
					When RewardTrackable = 1 then 'Yes'
				End
From [Relational].[Acquirer] as a
inner join Staging.TrackableRetailers as b
	on	a.AcquirerID = b.AcquirerID and
		Not (	a.RewardTrackable = 1 and b.Trackable = 'Yes' or
			a.RewardTrackable = 0 and b.Trackable = 'No')


Update b
Set PartnerID = p.PartnerID,
	PartnerName = p.PartnerName	
From Staging.TrackableRetailers as b
inner join Relational.Partner as p
	on b.BrandID = p.BrandID
Where b.PartnerID is null or b.PartnerName is null