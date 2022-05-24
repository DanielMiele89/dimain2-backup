CREATE TABLE [Relational].[MFDD_Households] (
    [ID]            INT          IDENTITY (1, 1) NOT NULL,
    [FanID]         BIGINT       NOT NULL,
    [SourceUID]     VARCHAR (20) NOT NULL,
    [BankAccountID] INT          NOT NULL,
    [HouseholdID]   INT          NOT NULL,
    [StartDate]     DATE         NOT NULL,
    [EndDate]       DATE         NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [CIX_HouseholdID_SourceUID]
    ON [Relational].[MFDD_Households]([HouseholdID] ASC)
    INCLUDE([SourceUID]) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];


GO
CREATE NONCLUSTERED INDEX [CIX_SourceUID]
    ON [Relational].[MFDD_Households]([SourceUID] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];

