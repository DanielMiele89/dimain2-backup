/*
	Author:			Stuart Barnley
	Date:			23-05-2014

	Description:	This stored procedure is used to populate the report R_0019.

					Pull a list of tables that been analysed

Update:			N/A
					
*/
CREATE Procedure [Staging].[SSRS_R0019_DataTables]
				 
as

Select Distinct DataDate,Tablename  
from
[Staging].[PostSFDEmailEvaluation_CJStageCounts]
Order by DataDate Desc, TableName