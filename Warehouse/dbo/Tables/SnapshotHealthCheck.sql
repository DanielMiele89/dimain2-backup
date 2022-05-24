CREATE TABLE [dbo].[SnapshotHealthCheck] (
    [ID]           INT             IDENTITY (1, 1) NOT NULL,
    [CheckDate]    DATETIME        NULL,
    [IsError]      BIT             NULL,
    [ErrorMessage] NVARCHAR (4000) NULL
);

