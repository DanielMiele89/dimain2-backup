CREATE TABLE [APW].[SnapshotHealthCheck] (
    [ID]           INT             IDENTITY (1, 1) NOT NULL,
    [CheckDate]    DATETIME        CONSTRAINT [DF_APW_SnapshotHealthCheck_CheckDate] DEFAULT (getdate()) NULL,
    [IsError]      BIT             NULL,
    [ErrorMessage] NVARCHAR (4000) NULL,
    CONSTRAINT [PK_APW_SnapshotHealthCheck] PRIMARY KEY CLUSTERED ([ID] ASC)
);

