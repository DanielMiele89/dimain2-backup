CREATE TABLE [WHB].[Inbound_Files] (
    [ID]            INT            IDENTITY (1, 1) NOT NULL,
    [TableName]     VARCHAR (100)  NULL,
    [LoadDate]      DATETIME2 (7)  NULL,
    [FileName]      NVARCHAR (100) NULL,
    [FileProcessed] BIT            NULL
);

