CREATE TABLE [InsightArchive].[CustomerCheck] (
    [FanID]            INT  NOT NULL,
    [ActivationDate]   DATE NOT NULL,
    [DeactivationDate] DATE NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC)
);

