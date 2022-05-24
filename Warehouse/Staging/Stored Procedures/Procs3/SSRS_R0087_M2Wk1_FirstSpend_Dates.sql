Create procedure Staging.SSRS_R0087_M2Wk1_FirstSpend_Dates
as

Select	Distinct [Date]
from Relational.SFD_MOT3Wk1_PartnerSpend as a
Order by [Date] Desc