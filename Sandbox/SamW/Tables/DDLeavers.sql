CREATE TABLE [SamW].[DDLeavers] (
    [LastTransactionDate] DATETIME     NULL,
    [Leavers]             INT          NULL,
    [BrandName]           VARCHAR (50) NOT NULL,
    [SectorName]          VARCHAR (50) NULL
);


GO
CREATE CLUSTERED INDEX [ix_ComboID]
    ON [SamW].[DDLeavers]([LastTransactionDate] ASC);

