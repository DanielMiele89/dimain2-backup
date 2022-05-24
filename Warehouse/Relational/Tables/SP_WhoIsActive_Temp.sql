CREATE TABLE [Relational].[SP_WhoIsActive_Temp] (
    [dd hh:mm:ss.mss] VARCHAR (8000)  NULL,
    [additional_info] XML             NULL,
    [database_name]   NVARCHAR (128)  NULL,
    [host_name]       NVARCHAR (128)  NULL,
    [login_name]      NVARCHAR (128)  NOT NULL,
    [program_name]    NVARCHAR (128)  NULL,
    [query_plan]      XML             NULL,
    [session_id]      SMALLINT        NOT NULL,
    [sql_command]     XML             NULL,
    [sql_text]        XML             NULL,
    [status]          VARCHAR (30)    NOT NULL,
    [tran_log_writes] NVARCHAR (4000) NULL,
    [tran_start_time] DATETIME        NULL,
    [wait_info]       NVARCHAR (4000) NULL,
    [collection_time] DATETIME        NULL
);

