/*
	Author:			Stuart Barnley

	Date:			6th June 2016

	Purpose:		To indicate the last time files were received
	
*/

CREATE Procedure [Staging].[SSRS_R0124_FilesProcessed]
with execute as owner
as

IF OBJECT_ID('tempdb..#feedsummary') IS NOT NULL DROP TABLE #feedsummary
--use SLC_Report
select (select    abbreviation 
            from  SLC_Report.dbo.transactionvector 
            where id=vectorid) Vector,
       min(addeddate) [Import Start Time], 
       max(addeddate) [Import End Time], 
       VectorMajorID, count(*) TransCount, min(VectorminorID) MinRow, max(vectorminorid) MaxRow,
       cast(100*count(*) / ( 1.0 + max(VectorminorID) - min(vectorminorid) ) as decimal(9,0)) Density, 
       /*SLC_Report.dbo.fn_FormatTimeSpan(min(addeddate),max(addeddate))*/ 0 'Duration',
       /*datediff(ms,min(addeddate), max(addeddate))/count(*)/1000.0*/ 0 [S/T],
       cast(sum(case when status in (1,9,10) then 1 else 0 end)*100/count(*) as nvarchar)+'%' OK,
       cast(sum(case when status in (1) then 1 else 0 end)*100/count(*) as nvarchar)+'%' Inc,
       cast(sum(case when status in (9,10) then 1 else 0 end)*100/count(*) as nvarchar)+'%' Uninc,
       cast(sum(case when status in (5) then 1 else 0 end)*100/count(*) as nvarchar)+'%' DupeV,
       cast(sum(case when status in (6) then 1 else 0 end)*100/count(*) as nvarchar)+'%'[Dupe£],
       SLC_Report.dbo.fn_FormatDateRange(min(transactiondate),max(transactiondate)) TransactionDateRange
            into #feedsummary
       from SLC_Report.dbo.match 
       where vectorid not in (14) and addeddate > dateadd(d,-30,GETDATE()) --- specify how far you want to go back -- currently set at 7 days (-7)
       group by vectorid, vectormajorid
       order by 2 desc,  max(addeddate) desc


IF OBJECT_ID('tempdb..#Vectors') IS NOT NULL DROP TABLE #Vectors
Select  Vector,
		ROW_NUMBER() OVER(ORDER BY Vector Asc) % 2 AS RowNo
Into #Vectors
From (
Select Distinct Vector
From #feedsummary
Where Vector <> 'RBSG'
) as a


select a.*,
		v.RowNo
		
from #feedsummary as a
inner join #Vectors as v
	on a.Vector = v.Vector order by 1,2 desc

