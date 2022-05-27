CREATE TABLE [Staging].[ALS_Retailer_Cycle] (
    [ID]                INT  IDENTITY (1, 1) NOT NULL,
    [PartnerID]         INT  NULL,
    [AnalysisStartDate] DATE NULL,
    [CycleStartDate]    DATE NULL,
    [CycleEndDate]      DATE NULL,
    CONSTRAINT [PK_ALS_Retailer_Cycle] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_ALS_Retailer_Cycle]
    ON [Staging].[ALS_Retailer_Cycle]([PartnerID] ASC, [CycleStartDate] ASC, [CycleEndDate] ASC);

