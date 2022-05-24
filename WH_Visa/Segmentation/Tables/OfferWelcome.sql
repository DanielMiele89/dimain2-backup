CREATE TABLE [Segmentation].[OfferWelcome] (
    [ID]          INT IDENTITY (1, 1) NOT NULL,
    [IronOfferID] INT NOT NULL,
    [ClubID]      INT NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [UQ_OfferWelcome_IronofferIDClubID] UNIQUE NONCLUSTERED ([IronOfferID] ASC, [ClubID] ASC)
);

