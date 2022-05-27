CREATE TABLE [Staging].[ALS_Control_Trans_Results] (
    [ID]                INT          IDENTITY (1, 1) NOT NULL,
    [IsRecentActivity]  BIT          NULL,
    [RetailerID]        INT          NULL,
    [AnalysisStartDate] DATE         NULL,
    [CycleStartDate]    DATE         NULL,
    [CycleEndDate]      DATE         NULL,
    [AnchorSegmentType] VARCHAR (50) NULL,
    [CycleMembers]      INT          NULL,
    [Transactions]      INT          NULL,
    [Spenders]          INT          NULL,
    [Spend]             INT          NULL,
    CONSTRAINT [PK_ALS_Control_Trans_Results] PRIMARY KEY CLUSTERED ([ID] ASC)
);

