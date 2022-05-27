CREATE TABLE [dbo].[WarehouseLoadAudit] (
    [ID]           INT           IDENTITY (1, 1) NOT NULL,
    [ProcName]     VARCHAR (50)  NOT NULL,
    [RunDateTime]  DATETIME2 (7) NOT NULL,
    [RowsInserted] INT           NULL,
    [RowsUpdated]  INT           NULL,
    [RowsDeleted]  INT           NULL
);

