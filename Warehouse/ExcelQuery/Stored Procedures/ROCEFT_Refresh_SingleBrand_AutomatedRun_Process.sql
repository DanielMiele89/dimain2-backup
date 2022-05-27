
/********************************************************************************************
	Name: ExcelQuery.ROCEFT_Refresh_SingleBrand_AutomatedRun_Process
	Desc: To automatically refresh the brands in the relevant table in the ROC tool
	Auth: Zoe Taylor

	Change History
			ZT 09/07/2018 - sProc created
	
*********************************************************************************************/


CREATE PROCEDURE [ExcelQuery].[ROCEFT_Refresh_SingleBrand_AutomatedRun_Process] 
AS 
BEGIN

DECLARE @Message VARCHAR(MAX)
	, @SubjectMessage VARCHAR(max)

		/******************************************************************		
				Get brands to add to the tool  
		******************************************************************/

		IF OBJECT_ID('tempdb..#BrandsToAdd') IS NOT NULL 
		DROP TABLE #BrandsToAdd

		Select top 3 
				* 
				, ROW_NUMBER () OVER (order by PriorityFlag desc) RowID
		Into #BrandsToAdd
		From ExcelQuery.ROCEFT_Refresh_SingleBrand_AutomatedRun
		Where RefreshDate is NULL
		Order by PriorityFlag Desc, ID asc

		If (Select count(*) from #BrandsToAdd) = 0
		Begin 
			
			sET @SubjectMessage = 'Brands added to ROC tool - None'
			Set @Message = 'No brands have been added to the ROC tool.<br><br> Regards <br><br> Data Operations'

		End --If @@ROWCOUNT = 0

		If (Select count(*) from #BrandsToAdd) > 0
		Begin 
				/******************************************************************		
						Loop through brands 
				******************************************************************/

				DECLARE @qry nvarchar(max)
							, @RunID int = 1 
							, @MaxID int
							, @BrandID int

				Select @MaxID = MAX(a.RowID) 
				From #BrandsToAdd a

					While @RunID <= @MaxID
					Begin
		
						Select @BrandID = BrandID
						From #BrandsToAdd a
						Where @RunID = a.RowID
						Select @BrandID

								Insert into staging.JobLog_Temp
								Select	StoredProcedureName = 'ExcelQuery.ROCEFT_Refresh_SingleBrand_AutomatedRun_Process - BrandID ' + cast(@BrandID as nvarchar(10))+ '',
										TableSchemaName = 'ExcelQuery',
										TableName = 'ExcelQuery.ROCEFT_Refresh_SingleBrand_AutomatedRun',
										StartDate = GETDATE(),
										EndDate = null,
										TableRowCount  = null,
										AppendReload = 'U'

						Set @Qry = 'EXEC ExcelQuery.ROCEFT_Refresh_SingleBrand_v3 ' + cast(@BrandID as nvarchar(10))+ ''
		
						Select (@Qry)
						--Exec (@qry)

						Update a
						Set RefreshDate = GETDATE() 
						From ExcelQuery.ROCEFT_Refresh_SingleBrand_AutomatedRun a
						Inner join #BrandsToAdd b 
							on b.ID = A.ID
						Where b.RowID = @RunID

								Update  staging.JobLog_Temp
								Set		EndDate = GETDATE()	
								where	StoredProcedureName = 'ExcelQuery.ROCEFT_Refresh_SingleBrand_AutomatedRun_Process - BrandID ' + cast(@BrandID as nvarchar(10))+ '' and
										TableSchemaName = 'ExcelQuery' and
										TableName = 'ExcelQuery.ROCEFT_Refresh_SingleBrand_AutomatedRun' and
										TableRowCount is null

								Insert into staging.JobLog
								select [StoredProcedureName],
									[TableSchemaName],
									[TableName],
									[StartDate],
									[EndDate],
									[TableRowCount],
									[AppendReload]
								from staging.JobLog_Temp
								truncate table staging.JobLog_Temp

						Set @RunID = @RunID + 1

					End -- While

				Select a.BrandID, b.BrandName, a.RefreshDate
				Into #BrandsAdded
				From ExcelQuery.ROCEFT_Refresh_SingleBrand_AutomatedRun a
				Inner join Relational.Brand b 
					on b.BrandID = a.BrandID
				Where cast(RefreshDate as date) = CAST(GETDATE() as date) 
	
				/******************************************************************		
						Procedure Logic 
				******************************************************************/
				-- Set email message

				DECLARE @Table VARCHAR(MAX)
				SET @Table = CAST((SELECT 
					'<td nowrap="nowrap">' + ISNULL(CAST(BrandID AS VARCHAR), '')
					+ '</td><td>' + ISNULL(BrandName, '')
					+ '</td><td>' + ISNULL(CAST(RefreshDate AS VARCHAR), '')
					+ '</td>'
				FROM #BrandsAdded
				FOR XML PATH ('tr'), type) as VARCHAR(MAX))

				DECLARE @Style VARCHAR(MAX)
				SET @Style = '<style>
				table {
					border-collapse: collapse;
				}

				p {
					font-family: Calibri;
				}

				th {
					padding: 10px;
				}

				table, td {
					padding: 0 10 0 10;
				}

				table, td, th {
					border: 1px solid black;
					font-family: Calibri;
				}
				</style>'

				DECLARE @Body VARCHAR(MAX)
				SET @Body = @Style + '
				<table style="border-collapse: collapse; border: 1px solid black">'
					+ '<tr>'
					+ '<th>BrandID</th><th>BrandName</th><th>RefreshDate</th>' -- Heading names
					+ '</tr>'
					+ replace(replace(replace( replace( @table, '&lt;', '<' ), '&gt;', '>' ), '&amp;', '&'), '<td>', '<td style="height:28px">')
					+ '</table>'

				SET @Message = 'The following brands have been added to the ROC Forecasting tool as part of the overnight processing: <br><br> ' + @Body + '<br><br> Regards <br><br> Data Operations'
				Set @SubjectMessage = 'Brands added to ROC tool'

			End --If @@ROWCOUNT > 0


exec msdb..sp_send_dbmail 
	@profile_name = 'Administrator',
	@recipients= 'insight@rewardinsight.com; zoe.taylor@rewardinsight.com',
	--@recipients= 'zoe.taylor@rewardinsight.com',
	@subject = @SubjectMessage,
	@execute_query_database = 'Warehouse',
	@body= @Message,
	@body_format = 'HTML', 
	@importance = 'HIGH'
			
						
End


