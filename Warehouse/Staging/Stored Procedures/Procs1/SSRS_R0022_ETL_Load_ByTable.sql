/*
	Author:			Stuart Barnley
	Date:			23-05-2014

	Description:	This stored procedure is used to populate the report R_0022.

					This stores the line by line data for the ETL load

Update:			N/A
					
*/
Create Procedure Staging.SSRS_R0022_ETL_Load_ByTable
				 @Date date
as

Select     	jl.*,
            Cast(Datediff(Minute,jl.StartDate,jl.EndDate) as Varchar) + ' Minutes'  as TimeTakentoRun,
            Case
                        When jl.EndDate is null then 'Yes'
                        Else 'No'
            End as DidAnySPsFail
From
      (select	  Max(Case
                              When StoredProcedureName = 'ETL_Build_Start' then StartDate
                              Else null
                        End) as StartDate,
                  Max(Case
                              When StoredProcedureName = 'ETL_Build_Start' then JobLogID
                              Else null
                        End)  as SD_JobID,
                  Max(Case
                              When StoredProcedureName = 'ETL_Build_End' then EndDate
                              Else null
                        End) as EndDate,
                  Max(Case
                              When StoredProcedureName = 'ETL_Build_End' then JobLogID
                              Else null
                        End)  as ED_JobID
      from warehouse.staging.joblog
      Where Cast(StartDate as date) = @Date
			
      ) as a
inner join warehouse.staging.joblog as jl
      on a.SD_JobID < jl.JobLogID and
         a.ED_JobID > jl.JobLogID

Order by JobLogID