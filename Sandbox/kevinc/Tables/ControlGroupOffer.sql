CREATE TABLE [kevinc].[ControlGroupOffer] (
    [ControlGroupOfferID] INT IDENTITY (1, 1) NOT NULL,
    [ControlGroupID]      INT NOT NULL,
    [ReportingOfferID]    INT NOT NULL,
    PRIMARY KEY CLUSTERED ([ControlGroupOfferID] ASC)
);

