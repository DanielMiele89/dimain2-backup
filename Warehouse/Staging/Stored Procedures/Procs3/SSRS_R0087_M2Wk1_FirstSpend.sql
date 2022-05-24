CREATE procedure Staging.SSRS_R0087_M2Wk1_FirstSpend @Date Date
as

Select	c.Email,
		c.FanID as [Customer ID],
		c.ClubID,
		a.LastSpend as FirstSpend
from Relational.SFD_MOT3Wk1_PartnerSpend as a
inner join Relational.customer as c
	on a.FanID = c.FanID
Where a.Date = @Date