/*
	Author:			Stuart Barnley
	Date:			23-05-2014

	Description:	This stored procedure is used to populate the report R_0056.

					This stores the overall data for the ETL load

Update:			N/A
					
*/
CREATE Procedure [Staging].[SSRS_R0056_ETL_Load]
				 @Date date
as

Select      a.StartDate,
            a.EndDate,
            Cast(Datediff(Minute,a.StartDate,a.EndDate) as Varchar) + ' Minutes'  as TimeTakentoRun,
            Max(Case
                        When jl.EndDate is null then 'Yes'
                        Else 'No'
                  End) as DidAnySPsFail
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
      from Relational.joblog
      Where Cast(StartDate as date) = @Date
      ) as a
inner join Relational.joblog as jl
      on a.SD_JobID < JobLogID and
         a.ED_JobID > JobLogID
Group by a.StartDate,a.EndDate