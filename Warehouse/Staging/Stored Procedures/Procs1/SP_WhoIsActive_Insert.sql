
CREATE Procedure [Staging].[SP_WhoIsActive_Insert]
	As
		Begin
			
			SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
			/*

			EXEC sp_WhoIsActive @help = 1

			DECLARE @s VarChar(MAX)

			If Object_ID('/* Destination table */') Is Not Null Drop Table /* Destination table */
			EXEC sp_WhoIsActive 
				 @return_schema = 1
			   , /* List of options */
			   , @schema = @s OUTPUT

			SET @s = REPLACE(@s, '<table_name>', '/* Destination table */')

			EXEC(@s)

			*/
				
				--Declare @StartTime DateTime = GetDate()
				--	  , @Truncated DateTime
				--	  , @SP_WhoIsActive_Temp DateTime
				--	  , @SP_WhoIsActiveDelta_Temp DateTime
				--	  , @Blocking DateTime
				--	  , @Additional DateTime
				--	  , @SP_WhoIsActive DateTime
				--	  , @Delete DateTime

			/***************************************************************************************************
					Truncate tables
			***************************************************************************************************/
			
				Truncate Table Warehouse.Relational.SP_WhoIsActive_Temp
				Truncate Table Warehouse.Relational.SP_WhoIsActiveDelta_Temp
				--	Truncate Table Warehouse.Relational.SP_AvgTime

				--	Set @Truncated = GetDate()

			/***************************************************************************************************
					Fetch the bulk of the required data from SP_whoisactive
			***************************************************************************************************/

				EXEC sp_WhoIsActive 
					 @get_full_inner_text = 1
				   , @get_plans = 2
				   , @get_transaction_info = 1
				   , @get_outer_command = 1
				   , @get_additional_info = 1
				   , @output_column_list = '[%dd hh%][additional_info][database_name][host_name][login_name][program_name][query_plan][session_id][sql_command][sql_text][status][tran_log_writes][tran_start_time][wait_info][collection_time]'
				   , @destination_table = 'Warehouse.Relational.SP_WhoIsActive_Temp'

				--	Set @SP_WhoIsActive_Temp = GetDate()
				   
			--/***************************************************************************************************
			--		Fetch average time per query and batch step query plan from SP_whoisactive
			--***************************************************************************************************/

				--EXEC sp_WhoIsActive 
				--	 @get_plans = 1
				--   , @get_avg_time = 1
				--   , @not_filter_type = 'login'
				--   , @not_filter = 'SLCReplication'
				--   , @output_column_list = '[session_id][%dd hh%avg%][query_plan][sql_text]'
				--   , @destination_table = 'Warehouse.Relational.SP_AvgTime'
			   
			/***************************************************************************************************
					Fetch additonal information on blocked sessions
			***************************************************************************************************/
	
				If Object_ID('tempdb..#SP_Blocking') Is Not Null Drop Table #SP_Blocking
				Create Table #SP_Blocking (RootOfEvil VarChar(1)
										 , SPID nVarChar(10)
										 , BlockedBy nVarChar(10)
										 , isolation_level VarChar(14)
										 , lock_timeout Int
										 , logical_reads BigInt
										 , reads BigInt
										 , command nVarChar(32)
										 , wait_type nVarChar(60)
										 , waiting_minutes Int
										 , executing_text nVarChar(max));
			  
				Begin Try
					Declare @Processes table (spid Int
											, BlockingSPID Int
											, dbid Int);

					Insert @Processes (spid
									 , BlockingSPID
									 , dbid)
					Select s.spid
    					 , s.blocked as BlockingSPID
    					 , s.dbid
					From sys.sysprocesses s
					Where s.spid > 50;

					With Blocking (SPID
								 , BlockingSPID
								 , dbid
								 , RowNum
								 , Rank)
					as (Select s.SPID
         					 , s.BlockingSPID
         					 , s.dbid
         					 , RowNum = ROW_NUMBER() Over (Order by s.SPID)
         					 , [Rank] = 0
     					 From @Processes s
     					 Where s.BlockingSPID = 0
     					 And exists (Select s1.spid
									 From @Processes s1
        							 Where s.SPID = s1.BlockingSPID)  -- anchor those who are blocked
     					 Union all
     					 Select r.SPID
        					  , r.BlockingSPID
        					  , r.dbid
        					  , d.RowNum
        					  , [Rank] = d.[Rank] + 1
     					 From @Processes r
						 Join Blocking d
        					on r.BlockingSPID = d.SPID
    					Where r.BlockingSPID > 0)  --Those who are blocked

					Insert Into #SP_Blocking
					Select Distinct
						   Case
								When bl.BlockingSpid = 0 Then 'Y'
								Else ''
       					   End as RootOfEvil
    					 , Convert(nVarChar(10),bl.SPID) as SPID
    					 , Case
								When bl.BlockingSpid = 0 Then ''
								Else CasT(bl.BlockingSpid as nVarChar(10))
       					   End as BlockedBy
    					 , Case se.transaction_isolation_level
         						When 1 Then 'ReadUncomitted'
         						When 2 Then 'ReadCommitted'
         						When 3 Then 'Repeatable'
         						When 4 Then 'Serializable'
         						When 5 Then 'Snapshot'
         						Else 'Unknown'
       					   End as isolation_level
    					 , se.lock_timeout
    					 , se.logical_reads
    					 , se.reads
    					 , rq.command
    					 , Coalesce(rq.wait_type, rq.last_wait_type) as wait_type
    					 , Convert(Int, rq.wait_time/1000./60.) as waiting_minutes
    					 , Coalesce(Case tx.encrypted
											When 1 Then 'Encrypted'
											Else Case
            					 					 When bl.BlockingSpid=0 Then tx.text
            										 Else convert(nVarChar(250), tx.text)
												 End
									End, Convert(nVarChar(250),se.status)) as executing_text
					From Blocking bl
					Join sys.dm_exec_connections c
						on c.session_id = bl.spid
					Left Join sys.dm_exec_requests rq
						on c.session_id = rq.session_id
					Left Join sys.dm_exec_sessions se
						on c.session_id = se.session_id
					Outer Apply sys.dm_exec_sql_text(c.most_recent_sql_handle) tx
					Outer Apply sys.dm_exec_query_plan(rq.plan_handle) pl;
				End Try
				Begin Catch

					waitfor delay '00:00:00.000'

				End Catch

				--	Set @Blocking = GetDate()

			/***************************************************************************************************
					Fetch additonal information not given by SP_whoisactive
			***************************************************************************************************/

				If Object_ID('tempdb..#SP_whoisactive_additional') Is Not Null Drop Table #SP_whoisactive_additional 
				SELECT Distinct
					   s.session_id
					 , s.[host_name]
					 , DB_NAME(r.database_id) as sourcedb
					 , DB_NAME(dt.database_id) as workdb
					 , s.[program_name]
					 , s.[status]
					 , s.memory_usage
					 , t.[text]
					 , mg.dop
					 , mg.requested_memory_kb
					 , mg.used_memory_kb
					 , mg.query_cost
				Into #SP_whoisactive_additional
				FROM sys.dm_exec_sessions s
				INNER JOIN sys.dm_exec_connections c 
					ON s.session_id = c.most_recent_session_id 
				LEFT OUTER JOIN sys.dm_exec_requests r 
					ON r.session_id = s.session_id 
				LEFT OUTER JOIN (
					SELECT
						session_id,
						database_id
					FROM sys.dm_tran_session_transactions t
					INNER JOIN sys.dm_tran_database_transactions dt
						ON t.transaction_id = dt.transaction_id  
					WHERE dt.database_id = DB_ID('tempdb') 
					GROUP BY  session_id,  database_id
				) dt
					ON s.session_id = dt.session_id
				CROSS APPLY sys.dm_exec_sql_text(COALESCE(r.sql_handle, c.most_recent_sql_handle)) t
				LEFT OUTER JOIN sys.dm_exec_query_memory_grants mg 
					ON s.session_id = mg.session_id 
 
				OUTER APPLY sys.dm_exec_query_plan(mg.plan_handle) AS qp
				WHERE s.session_id <> @@SPID

				--	Set @Additional = GetDate()

			/***************************************************************************************************
					Fetch CPU & read / write stats from SP_whoisactive
			***************************************************************************************************/

				EXEC sp_WhoIsActive 
					 @get_plans = 1
				   , @find_block_leaders = 1
				   , @get_task_info = 2 
				   , @delta_interval = 3
				   , @output_column_list = '[session_id][blocked_session_count][blocking_session_id][context_switches][CPU][CPU_delta][login_time][open_tran_count][physical_io][physical_reads][physical_reads_delta][reads][reads_delta][request_id][start_time][tasks][tempdb_allocations][tempdb_allocations_delta][tempdb_current][tempdb_current_delta][used_memory][used_memory_delta][writes][writes_delta][query_plan][sql_text]'
				   , @destination_table = 'Warehouse.Relational.SP_WhoIsActiveDelta_Temp'
								   
				--	Set @SP_WhoIsActiveDelta_Temp = GetDate()

			/***************************************************************************************************
					Get final dataset
			***************************************************************************************************/

				Insert Into Warehouse.Relational.SP_WhoIsActive
				Select ma.collection_time
					 , ma.session_id
					 , ma.host_name
					 , ma.database_name as source_db
					 , cm.workdb as work_db
					 , ma.program_name
					 , ma.login_name
					 , c.login_time
					 , ma.status as sp_status
					 , c.request_id
					 , c.blocking_session_id
					 , bl.isolation_level
					 , bl.lock_timeout
					 , bl.command
					 , bl.wait_type
					 , bl.waiting_minutes
					 , bl.executing_text
					 , c.blocked_session_count
					 , ma.wait_info
					 , c.start_time
					 , ma.[dd hh:mm:ss.mss]
				--	 , av.[dd hh:mm:ss.mss (avg)]
					 , ma.sql_text as full_sql_text
					 , ma.query_plan as full_query_plan
					 , ma.sql_command
					 , c.sql_text
					 , c.query_plan
					 , cm.query_cost
					 , ma.additional_info
					 , c.tempdb_allocations
					 , c.tempdb_current
					 , c.tempdb_allocations_delta
					 , c.tempdb_current_delta
					 , c.open_tran_count
					 , ma.tran_log_writes
					 , ma.tran_start_time
					 , c.tasks
					 , c.context_switches
					 , c.physical_io
					 , cm.dop
					 , cm.requested_memory_kb
					 , cm.used_memory_kb
					 , c.physical_reads
					 , c.CPU
					 , c.reads
					 , c.writes
					 , c.used_memory
					 , c.physical_reads_delta
					 , c.CPU_delta
					 , c.reads_delta
					 , c.writes_delta
					 , c.used_memory_delta
				From Warehouse.Relational.SP_WhoIsActive_Temp ma
				Left join Warehouse.Relational.SP_WhoIsActiveDelta_Temp c
					on ma.session_id = c.session_id
				--Left join Warehouse.Relational.SP_AvgTime av
				--	on ma.session_id = av.session_id
				Left Join #SP_whoisactive_additional cm
					on ma.session_id = cm.session_id
				Left join #SP_Blocking bl
					on c.session_id = bl.spid
					and c.blocking_session_id = bl.BlockedBy

					
				--	Set @SP_WhoIsActive = GetDate()


				Delete
				From Warehouse.Relational.SP_WhoIsActive
				Where collection_time < DateAdd(day, -7, GetDate())

				
				--	Set @Delete = GetDate()

				--Insert Into Sandbox.Rory.SP_Times
				--Select @StartTime as StartTime 
				--	 , @Truncated as Truncated 
				--	 , @SP_WhoIsActive_Temp as SP_WhoIsActive_Temp 
				--	 , @SP_WhoIsActiveDelta_Temp as SP_WhoIsActiveDelta_Temp 
				--	 , @Blocking as Blocking 
				--	 , @Additional as Additional 
				--	 , @SP_WhoIsActive as SP_WhoIsActive 
				--	 , @Delete as [Delete] 

		End
