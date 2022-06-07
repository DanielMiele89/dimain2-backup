CREATE TABLE [dbo].[Admin_Indexes_ReadWriteStats] (
    [ID]                 INT             IDENTITY (1, 1) NOT NULL,
    [RunDate]            DATETIME        NULL,
    [ObjectName]         NVARCHAR (128)  NULL,
    [IndexName]          [sysname]       NULL,
    [index_id]           INT             NOT NULL,
    [Writes]             BIGINT          NOT NULL,
    [Reads]              BIGINT          NULL,
    [IndexType]          NVARCHAR (60)   NULL,
    [FillFactor]         TINYINT         NOT NULL,
    [has_filter]         BIT             NULL,
    [filter_definition]  NVARCHAR (4000) NULL,
    [last_system_update] DATETIME        NULL,
    [last_user_update]   DATETIME        NULL
);

