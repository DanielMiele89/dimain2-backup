Create procedure Staging.SSRS_R0087_M2Wk1_FirstSpend_DateMAX
as

Select	Max([Date]) as MaxDate
from Relational.SFD_MOT3Wk1_PartnerSpend as a