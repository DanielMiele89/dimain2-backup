CREATE TABLE [Selections].[CampaignExecution_OutputTables] (
    [PreSelection_ALS_ID] INT           NULL,
    [PartnerID]           INT           NULL,
    [OutputTableName]     VARCHAR (100) NULL,
    [PriorityFlag]        INT           NULL,
    [InPartnerDedupe]     BIT           NULL,
    [RowNumber]           INT           NULL
);


GO
CREATE CLUSTERED INDEX [cix_SelectionsOutputTables_PartnerPriority]
    ON [Selections].[CampaignExecution_OutputTables]([PartnerID] ASC, [PriorityFlag] ASC);

