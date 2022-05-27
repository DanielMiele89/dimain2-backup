Create Procedure [Staging].[SSRS_R0028_TotalCounts]
				
as
 Select Sum(CustomerCount) as TotalRecords,
		Sum(Case
				When EmailEngaged = 1 then CustomerCount
				Else 0
			End ) as TotalEngaged
from [Staging].[SSRS_CustomerJourneyAssessmentV1_2_RolledUp]