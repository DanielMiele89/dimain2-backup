CREATE TABLE [iron].[WelcomeOffer] (
    [ID]          INT IDENTITY (1, 1) NOT NULL,
    [IronOfferID] INT NOT NULL,
    [ClubID]      INT NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [UQ_WelcomeOffer_IronofferIDClubID] UNIQUE NONCLUSTERED ([IronOfferID] ASC, [ClubID] ASC)
);

