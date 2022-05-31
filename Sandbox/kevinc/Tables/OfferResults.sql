CREATE TABLE [kevinc].[OfferResults] (
    [OfferResultID]    INT            IDENTITY (1, 1) NOT NULL,
    [ReportingOfferID] INT            NOT NULL,
    [Uplift]           DECIMAL (6, 2) NOT NULL
);

