CREATE TABLE [Relational].[AmexIronOfferCycles] (
    [AmexIronOfferID]    INT NULL,
    [OfferCyclesID]      INT NULL,
    [AmexControlGroupID] INT NOT NULL,
    PRIMARY KEY CLUSTERED ([AmexControlGroupID] ASC)
);

