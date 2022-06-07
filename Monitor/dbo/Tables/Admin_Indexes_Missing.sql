CREATE TABLE [dbo].[Admin_Indexes_Missing] (
    [ID]                    INT             IDENTITY (1, 1) NOT NULL,
    [RunDate]               DATETIME        NULL,
    [index_advantage]       DECIMAL (18, 2) NULL,
    [last_user_seek]        DATETIME        NULL,
    [Database.Schema.Table] NVARCHAR (4000) NULL,
    [equality_columns]      NVARCHAR (4000) NULL,
    [inequality_columns]    NVARCHAR (4000) NULL,
    [included_columns]      NVARCHAR (4000) NULL,
    [unique_compiles]       BIGINT          NOT NULL,
    [user_seeks]            BIGINT          NOT NULL,
    [avg_total_user_cost]   FLOAT (53)      NULL,
    [avg_user_impact]       FLOAT (53)      NULL,
    [Table Name]            NVARCHAR (128)  NULL,
    [Table Rows]            BIGINT          NOT NULL
);

