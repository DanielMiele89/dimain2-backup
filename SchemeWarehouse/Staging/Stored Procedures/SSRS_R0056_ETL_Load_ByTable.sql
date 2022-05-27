/*
	Author:			Stuart Barnley
	Date:			23-05-2014

	Description:	This stored procedure is used to populate the report R_0056.

					This stores the line by line data for the ETL load

Update:			N/A
					
*/
CREATE Procedure [Staging].[SSRS_R0056_ETL_Load_ByTable]
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
                              When StoredProcedureName = 'PennyforLondon ETL - Start' then StartDate
                              Else null
                        End) as StartDate,
                  Max(Case
                              When StoredProcedureName = 'PennyforLondon ETL - Start' then JobLogID
                              Else null
                        End)  as SD_JobID,
                  Max(Case
                              When StoredProcedureName = 'PennyforLondon ETL - End' then EndDate
                              Else null
                        End) as EndDate,
                  Max(Case
                              When StoredProcedureName = 'PennyforLondon ETL - End' then JobLogID
                              Else null
                        End)  as ED_JobID
      from Relational.Joblog
      Where Cast(StartDate as date) = @Date
			
      ) as a
inner join Relational.Joblog as jl
      on a.SD_JobID < jl.JobLogID and
         a.ED_JobID > jl.JobLogID

Order by JobLogID

