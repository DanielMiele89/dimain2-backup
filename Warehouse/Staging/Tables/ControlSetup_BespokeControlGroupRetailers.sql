CREATE TABLE [Staging].[ControlSetup_BespokeControlGroupRetailers] (
    [RetailerID] INT  NOT NULL,
    [StartDate]  DATE NOT NULL,
    [EndDate]    DATE NULL,
    CONSTRAINT [PK_ControlSetup_BespokeControlGroupRetailers] PRIMARY KEY CLUSTERED ([RetailerID] ASC)
);

