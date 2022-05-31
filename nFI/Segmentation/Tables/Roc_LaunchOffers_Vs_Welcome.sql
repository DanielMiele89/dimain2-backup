CREATE TABLE [Segmentation].[Roc_LaunchOffers_Vs_Welcome] (
    [LaunchOfferID] INT NOT NULL,
    [WelcomeOffer]  INT NOT NULL,
    [LiveOffer]     BIT NOT NULL,
    PRIMARY KEY CLUSTERED ([LaunchOfferID] ASC)
);

