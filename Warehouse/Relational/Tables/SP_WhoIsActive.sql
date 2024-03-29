﻿CREATE TABLE [Relational].[SP_WhoIsActive] (
    [collection_time]          DATETIME        NULL,
    [session_id]               SMALLINT        NOT NULL,
    [host_name]                NVARCHAR (128)  NULL,
    [source_db]                NVARCHAR (128)  NULL,
    [work_db]                  NVARCHAR (128)  NULL,
    [program_name]             NVARCHAR (128)  NULL,
    [login_name]               NVARCHAR (128)  NOT NULL,
    [login_time]               DATETIME        NULL,
    [sp_status]                VARCHAR (30)    NOT NULL,
    [request_id]               INT             NULL,
    [blocking_session_id]      SMALLINT        NULL,
    [isolation_level]          VARCHAR (14)    NULL,
    [lock_timeout]             INT             NULL,
    [command]                  NVARCHAR (32)   NULL,
    [wait_type]                NVARCHAR (60)   NULL,
    [waiting_minutes]          INT             NULL,
    [executing_text]           NVARCHAR (MAX)  NULL,
    [blocked_session_count]    VARCHAR (30)    NULL,
    [wait_info]                NVARCHAR (4000) NULL,
    [start_time]               DATETIME        NULL,
    [dd hh:mm:ss.mss]          VARCHAR (8000)  NULL,
    [full_sql_text]            XML             NULL,
    [full_query_plan]          XML             NULL,
    [sql_command]              XML             NULL,
    [sql_text]                 XML             NULL,
    [query_plan]               XML             NULL,
    [query_cost]               FLOAT (53)      NULL,
    [additional_info]          XML             NULL,
    [tempdb_allocations]       VARCHAR (30)    NULL,
    [tempdb_current]           VARCHAR (30)    NULL,
    [tempdb_allocations_delta] VARCHAR (30)    NULL,
    [tempdb_current_delta]     VARCHAR (30)    NULL,
    [open_tran_count]          VARCHAR (30)    NULL,
    [tran_log_writes]          NVARCHAR (4000) NULL,
    [tran_start_time]          DATETIME        NULL,
    [tasks]                    VARCHAR (30)    NULL,
    [context_switches]         VARCHAR (30)    NULL,
    [physical_io]              VARCHAR (30)    NULL,
    [dop]                      SMALLINT        NULL,
    [requested_memory_kb]      BIGINT          NULL,
    [used_memory_kb]           BIGINT          NULL,
    [physical_reads]           VARCHAR (30)    NULL,
    [CPU]                      VARCHAR (30)    NULL,
    [reads]                    VARCHAR (30)    NULL,
    [writes]                   VARCHAR (30)    NULL,
    [used_memory]              VARCHAR (30)    NULL,
    [physical_reads_delta]     VARCHAR (30)    NULL,
    [CPU_delta]                VARCHAR (30)    NULL,
    [reads_delta]              VARCHAR (30)    NULL,
    [writes_delta]             VARCHAR (30)    NULL,
    [used_memory_delta]        VARCHAR (30)    NULL
);


GO
CREATE CLUSTERED INDEX [CIX_SPWhoIsActive_CollectionTime]
    ON [Relational].[SP_WhoIsActive]([collection_time] ASC, [login_name] ASC, [session_id] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);

