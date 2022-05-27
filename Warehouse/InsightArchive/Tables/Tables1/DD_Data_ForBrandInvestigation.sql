CREATE TABLE [InsightArchive].[DD_Data_ForBrandInvestigation] (
    [FileID]            SMALLINT      NOT NULL,
    [TranDate]          DATE          NULL,
    [BankAccountID]     INT           NULL,
    [OIN]               INT           NULL,
    [Narrative]         NVARCHAR (18) NULL,
    [Amount]            MONEY         NULL,
    [SourceUID]         VARCHAR (20)  NULL,
    [ClubID]            SMALLINT      NULL,
    [IA_SuggestedBrand] VARCHAR (30)  NULL
);


GO
CREATE CLUSTERED INDEX [IDX_SUID]
    ON [InsightArchive].[DD_Data_ForBrandInvestigation]([Narrative] ASC) WITH (DATA_COMPRESSION = PAGE);


GO
CREATE NONCLUSTERED INDEX [IDX_CL]
    ON [InsightArchive].[DD_Data_ForBrandInvestigation]([OIN] ASC) WITH (DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];


GO
CREATE NONCLUSTERED INDEX [IDX_OIN]
    ON [InsightArchive].[DD_Data_ForBrandInvestigation]([Amount] ASC) WITH (DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];

