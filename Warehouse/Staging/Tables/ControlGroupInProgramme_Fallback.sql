CREATE TABLE [Staging].[ControlGroupInProgramme_Fallback] (
    [ID]         INT  IDENTITY (1, 1) NOT NULL,
    [RetailerID] INT  NOT NULL,
    [FanID]      INT  NOT NULL,
    [StartDate]  DATE NOT NULL,
    [EndDate]    DATE NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [UC_ControlGroupInProgramme_Fallback] UNIQUE NONCLUSTERED ([RetailerID] ASC, [FanID] ASC, [StartDate] ASC)
);

