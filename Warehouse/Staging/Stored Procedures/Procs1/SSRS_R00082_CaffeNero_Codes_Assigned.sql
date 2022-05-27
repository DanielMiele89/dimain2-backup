CREATE Procedure Staging.SSRS_R00082_CaffeNero_Codes_Assigned (@MembersBatch int,@ClubID int)
As

Select	c.FanID		as [Customer ID],
		c.email		as [Email],
		c.ClubID	as [ClubID],
		rc.Code		as [CaffeNeroBirthdayCode]
from [Relational].[RedemptionCode] as rc
inner join Relational.Customer as c
	on	rc.FanID = c.FanID
Where	rc.[MembersAssignedBatch] = @MembersBatch and 
		c.ClubID = @ClubID