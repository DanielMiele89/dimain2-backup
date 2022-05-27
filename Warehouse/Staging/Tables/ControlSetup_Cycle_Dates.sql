CREATE TABLE [Staging].[ControlSetup_Cycle_Dates] (
    [StartDate] DATE NOT NULL,
    [EndDate]   DATE NOT NULL,
    CONSTRAINT [PK_ControlSetup_Cycle_Dates] PRIMARY KEY CLUSTERED ([StartDate] ASC, [EndDate] ASC)
);

