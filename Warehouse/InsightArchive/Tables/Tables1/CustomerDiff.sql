CREATE TABLE [InsightArchive].[CustomerDiff] (
    [FanID]                INT  NOT NULL,
    [ActivationDate]       DATE NULL,
    [DeactivationDate]     DATE NULL,
    [CustActivationDate]   DATE NULL,
    [CustDeactivationDate] DATE NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC)
);

