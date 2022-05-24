CREATE TABLE [Relational].[SP_AvgTime] (
    [session_id]            SMALLINT     NOT NULL,
    [dd hh:mm:ss.mss (avg)] VARCHAR (15) NULL,
    [query_plan]            XML          NULL,
    [sql_text]              XML          NULL
);

